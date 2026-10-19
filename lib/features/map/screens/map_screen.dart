import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../data/models/safety_zone.dart';
import '../../../data/repositories/safety_zone_repository.dart';
import '../widgets/locality_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;

  const MapScreen({super.key, this.onNavigateToHome});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final SafetyZoneRepository _zoneRepo = SafetyZoneRepository();
  final TextEditingController _searchController = TextEditingController();

  List<SafetyZone> _zones = [];
  List<SafetyZone> _filteredZones = [];
  bool _isLoading = true;
  LatLng _userPosition =
      const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  double _mapRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final zones = await _zoneRepo.getSafetyZones();

    if (mounted) {
      setState(() {
        _zones = zones;
        _filteredZones = zones;
        _isLoading = false;
      });
    }

    await _determinePosition();
  }

  Future<void> _determinePosition({bool userInitiated = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (userInitiated && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location permission is needed to show your position.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (userInitiated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission is permanently denied. Please enable in Settings.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (userInitiated && mounted) {
        await Geolocator.openLocationSettings();
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final newPos = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _userPosition = newPos;
        });

        final distFromBlr = DistanceFormatter.calculateDistanceMeters(
          position.latitude,
          position.longitude,
          AppConstants.defaultLatitude,
          AppConstants.defaultLongitude,
        );

        // If user is within 50km of Bengaluru or explicitly asked to locate, move to location
        if (distFromBlr < 50000 || userInitiated) {
          _mapController.move(newPos, 15.0);
        } else {
          _mapController.move(
            const LatLng(
                AppConstants.defaultLatitude, AppConstants.defaultLongitude),
            13.0,
          );
        }
      }
    } catch (_) {}
  }

  void focusOnZone(SafetyZone zone) {
    final target = LatLng(zone.latitude, zone.longitude);
    _mapController.move(target, 15.0);
    LocalityBottomSheet.show(context, zone);
  }

  void _onSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredZones = _zones;
      } else {
        _filteredZones = _zones.where((z) {
          return z.areaName.toLowerCase().contains(clean) ||
              z.safetyTips.toLowerCase().contains(clean);
        }).toList();

        if (_filteredZones.isNotEmpty) {
          final first = _filteredZones.first;
          _mapController.move(LatLng(first.latitude, first.longitude), 14.0);
        }
      }
    });
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        title: Text('Safety Radar Legend', style: AppTypography.headlineSm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(AppColors.secondary, 'High Safety Zone (7.5 - 10.0)',
                'Verified well-illuminated main corridors with steady footfall.'),
            const SizedBox(height: 12),
            _legendItem(AppColors.tertiary, 'Moderate Zone (6.0 - 7.4)',
                'Quiet residential roads, variable lighting, standard caution advised.'),
            const SizedBox(height: 12),
            _legendItem(AppColors.error, 'Caution Zone (1.0 - 5.9)',
                'Higher incident history or unlit stretches. Avoid solo night travel.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLg.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySm.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // FlutterMap Tile & Marker Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition,
              initialZoom: AppConstants.defaultZoom,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (camera, hasGesture) {
                if ((camera.rotation - _mapRotation).abs() > 0.5) {
                  setState(() {
                    _mapRotation = camera.rotation;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.mapTileUrl,
                fallbackUrl: AppConstants.mapTileFallbackUrl,
                subdomains: AppConstants.mapSubdomains,
                userAgentPackageName: 'com.safetour.app',
                retinaMode: false,
                tileBuilder: darkModeTileBuilder,
              ),

              // Safety Zone Circles Overlay
              CircleLayer(
                circles: _filteredZones.map((zone) {
                  return CircleMarker(
                    point: LatLng(zone.latitude, zone.longitude),
                    radius: zone.radiusMeters.toDouble(),
                    useRadiusInMeter: true,
                    color: ScoreCalculator.getMapCircleFillColor(
                        zone.overallScore),
                    borderColor: ScoreCalculator.getMapCircleBorderColor(
                        zone.overallScore),
                    borderStrokeWidth: 1.2,
                  );
                }).toList(),
              ),

              // Zone Pin Markers (Stitch Style with Score Pill & Tail)
              MarkerLayer(
                rotate: true,
                alignment: Alignment.topCenter,
                markers: [
                  // User Location Pin
                  Marker(
                    point: _userPosition,
                    width: 34,
                    height: 34,
                    rotate: true,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Zone Markers matching Stitch design
                  ..._filteredZones.map((zone) {
                    final isHigh = zone.overallScore >= 7.5;
                    final isMod =
                        zone.overallScore >= 6.0 && zone.overallScore < 7.5;
                    final color = isHigh
                        ? AppColors.secondary
                        : isMod
                            ? AppColors.tertiary
                            : AppColors.error;
                    final bg = isHigh
                        ? AppColors.darkGreenCard
                        : isMod
                            ? AppColors.darkAmberCard
                            : const Color(0xFF261214);

                    return Marker(
                      point: LatLng(zone.latitude, zone.longitude),
                      width: 140,
                      height: 48,
                      rotate: true,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => LocalityBottomSheet.show(context, zone),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: bg.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.6),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isHigh
                                        ? Icons.verified_user_rounded
                                        : Icons.info_outline_rounded,
                                    size: 14,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    zone.overallScore.toStringAsFixed(1),
                                    style: AppTypography.labelSm.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      zone.areaName,
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.onSurface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Downward Pointer Tail
                            Transform.translate(
                              offset: const Offset(0, -4),
                              child: Transform.rotate(
                                angle: 0.785398, // 45 degrees
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top Floating Search Bar (Clean Stitch UI)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF181818).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_rounded,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search destination, safe zones...',
                        hintStyle: AppTypography.bodySm.copyWith(
                          color: AppColors.outline,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    )
                  else
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),

          // Right-side floating action controls
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              children: [
                _floatingCompassButton(),
                const SizedBox(height: 12),
                _floatingCircleButton(
                  icon: Icons.legend_toggle_rounded,
                  onTap: _showLegend,
                  tooltip: 'Safety Legend',
                ),
                const SizedBox(height: 12),
                _floatingCircleButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _determinePosition(userInitiated: true),
                  tooltip: 'Locate Me',
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _floatingCompassButton() {
    final isRotated = _mapRotation.abs() > 1.0;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(
          color: isRotated
              ? AppColors.secondary.withValues(alpha: 0.8)
              : AppColors.outlineVariant.withValues(alpha: 0.5),
          width: isRotated ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Transform.rotate(
          angle: -(_mapRotation * 3.141592653589793 / 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 3,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        onPressed: () {
          _mapController.rotate(0.0);
          setState(() {
            _mapRotation = 0.0;
          });
        },
        tooltip: 'Reset North (Gyro)',
      ),
    );
  }

  Widget _floatingCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.onSurface, size: 22),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }
}
