import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../data/models/safety_zone.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/safety_zone_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../map/widgets/safety_score_badge.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMap;

  const HomeScreen({
    super.key,
    this.onNavigateToMap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SafetyZoneRepository _zoneRepo = SafetyZoneRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _locationDetailsKey = GlobalKey();

  String _userName = 'Alex';
  List<SafetyZone> _zones = [];
  SafetyZone? _currentZone;
  bool _isLoading = true;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLocationDetails() {
    final ctx = _locationDetailsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final name = await _profileRepo.getUserName();
    _userName = name.split(' ').first;
    _zones = await _zoneRepo.getSafetyZones();

    await _determineLocation();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _determineLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackZone();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setFallbackZone();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackZone();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      if (_zones.isNotEmpty) {
        final closest =
            _zoneRepo.findClosestZone(pos.latitude, pos.longitude, _zones);
        if (mounted) {
          setState(() {
            _currentZone = closest ?? _zones.first;
          });
        }
      }
    } catch (_) {
      _setFallbackZone();
    }
  }

  void _setFallbackZone() {
    if (_zones.isNotEmpty && mounted) {
      setState(() {
        _currentZone = _zones.first;
      });
    }
  }

  Future<void> _triggerSOS() async {
    final uri = Uri(scheme: 'tel', path: AppConstants.policeEmergency);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening phone dialer for 112...'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = _currentZone;
    final score = zone?.overallScore ?? 8.4;
    final scoreColor = ScoreCalculator.getScoreColor(score);
    final isSafe = score >= 7.5;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerLow,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  children: [
                    // Top SafeTour Brand Header
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.security_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SafeTour',
                          style: AppTypography.headlineMd.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Greeting Header
                    Text(
                      'Hello, $_userName.',
                      style: AppTypography.displayLg.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Safety Status Pill
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: scoreColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: scoreColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSafe
                                  ? 'You are in a High Safety area'
                                  : score >= 6.0
                                      ? 'You are in a Moderate Safety area'
                                      : 'Caution: Heightened vigilance advised',
                              style: AppTypography.bodyMd.copyWith(
                                color: scoreColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bento Card 1: Current Location & Score
                    GestureDetector(
                      onTap: _scrollToLocationDetails,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                AppColors.outlineVariant.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CURRENT LOCATION',
                                        style: AppTypography.labelSm.copyWith(
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        zone?.areaName ?? 'Central Bengaluru',
                                        style:
                                            AppTypography.headlineMd.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 15,
                                            color: scoreColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isSafe
                                                ? 'High Safety Area'
                                                : 'Moderate Safety Area',
                                            style:
                                                AppTypography.bodySm.copyWith(
                                              color: scoreColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.trending_up_rounded,
                                        color: AppColors.secondary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Stable',
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Score display
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  score.toStringAsFixed(1),
                                  style: AppTypography.displayLg.copyWith(
                                    color: scoreColor,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ 10 Safety Score',
                                  style: AppTypography.bodyLg.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Mini Radar Preview Card
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Radar Grid Artwork
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _RadarGridPainter(),
                                    ),
                                  ),
                                  // Bottom Tag
                                  Positioned(
                                    bottom: 10,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color:
                                              scoreColor.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: scoreColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Safe Zone Active',
                                            style:
                                                AppTypography.labelSm.copyWith(
                                              color: scoreColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Tap to view safety details below',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bento Card 2: Giant SOS Button (Exact Stitch UI)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return GestureDetector(
                              onTap: _triggerSOS,
                              child: Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceContainerHigh,
                                  border: Border.all(
                                    color: AppColors.error.withValues(
                                      alpha: _glowAnimation.value,
                                    ),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.error.withValues(
                                        alpha: _glowAnimation.value * 0.45,
                                      ),
                                      blurRadius: 50,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.emergency_rounded,
                                      size: 46,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'SOS',
                                      style: AppTypography.headlineMd.copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Text(
                                      'CALL 112',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.error,
                                        letterSpacing: 2.0,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bento Card 3: Location Details (Below SOS)
                    Container(
                      key: _locationDetailsKey,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LOCALITY SAFETY DETAILS',
                                    style: AppTypography.labelSm.copyWith(
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.onNavigateToMap != null)
                                GestureDetector(
                                  onTap: widget.onNavigateToMap,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.map_rounded,
                                          color: AppColors.primary,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Map',
                                          style: AppTypography.labelSm.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Area Name & Score Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      zone?.areaName ?? 'Central Bengaluru',
                                      style: AppTypography.headlineMd.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bengaluru Urban • ${zone?.radiusMeters ?? 500}m Radius',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SafetyScoreBadge(
                                score: zone?.overallScore ?? 8.4,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 4 Metrics Grid (Day, Night, Crowd, Lighting)
                          Row(
                            children: [
                              Expanded(
                                child: _HomeMetricCard(
                                  icon: Icons.wb_sunny_rounded,
                                  iconColor: AppColors.tertiary,
                                  title: 'Day Score',
                                  value:
                                      '${(zone?.dayScore ?? 8.6).toStringAsFixed(1)} / 10',
                                  subtext: 'Transit & Footfall',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HomeMetricCard(
                                  icon: Icons.nightlight_round,
                                  iconColor: AppColors.primary,
                                  title: 'Night Score',
                                  value:
                                      '${(zone?.nightScore ?? 8.2).toStringAsFixed(1)} / 10',
                                  subtext: 'Lighting & Safety',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _HomeMetricCard(
                                  icon: Icons.groups_rounded,
                                  iconColor: AppColors.secondary,
                                  title: 'Crowd Density',
                                  value: '${zone?.crowdRating ?? 8} / 10',
                                  subtext: (zone?.crowdRating ?? 8) >= 8
                                      ? 'Very High Footfall'
                                      : (zone?.crowdRating ?? 8) >= 5
                                          ? 'Moderate Density'
                                          : 'Quiet / Sparse',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HomeMetricCard(
                                  icon: Icons.lightbulb_rounded,
                                  iconColor: AppColors.tertiary,
                                  title: 'Street Lighting',
                                  value: '${zone?.lightingRating ?? 8} / 10',
                                  subtext: (zone?.lightingRating ?? 8) >= 8
                                      ? 'Well Illuminated'
                                      : (zone?.lightingRating ?? 8) >= 6
                                          ? 'Adequate Stretches'
                                          : 'Dim / Patchy',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Safety Tips Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Local Safety Tips',
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (zone != null && zone.safetyTips.isNotEmpty)
                                      ? zone.safetyTips
                                      : 'Stay on illuminated main streets and prefer app-based cabs after 10 PM.',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (widget.onNavigateToMap != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: widget.onNavigateToMap,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                icon:
                                    const Icon(Icons.explore_rounded, size: 18),
                                label: const Text(
                                  'View on Interactive Map',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HomeMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtext;

  const _HomeMetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineSm.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF75DAA8).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Concentric circles
    final center = Offset(size.width * 0.7, size.height * 0.5);
    canvas.drawCircle(center, 30, paint);
    canvas.drawCircle(center, 65, paint);
    canvas.drawCircle(center, 105, paint);

    // Grid lines
    for (double x = 0; x < size.width; x += 35) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 1,
      );
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
