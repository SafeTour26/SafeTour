import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/models/sos_event.dart';
import '../../../data/repositories/emergency_repository.dart';

class SOSEmergencyScreen extends StatefulWidget {
  final String userId;
  final double currentLatitude;
  final double currentLongitude;
  final List<EmergencyContact> contacts;

  const SOSEmergencyScreen({
    super.key,
    required this.userId,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.contacts,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required double currentLatitude,
    required double currentLongitude,
    required List<EmergencyContact> contacts,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => SOSEmergencyScreen(
          userId: userId,
          currentLatitude: currentLatitude,
          currentLongitude: currentLongitude,
          contacts: contacts,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen>
    with SingleTickerProviderStateMixin {
  final EmergencyRepository _emergencyRepo = EmergencyRepository();

  int _countdown = 5;
  Timer? _timer;
  bool _isDispatched = false;
  SOSEvent? _sosEvent;
  double _dragPosition = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _dispatchEmergency();
      }
    });
  }

  Future<void> _dispatchEmergency() async {
    setState(() {
      _isDispatched = true;
    });

    final event = await _emergencyRepo.triggerSOSEvent(
      userId: widget.userId,
      latitude: widget.currentLatitude,
      longitude: widget.currentLongitude,
    );

    if (mounted) {
      setState(() {
        _sosEvent = event;
      });
    }

    // Broadcast SMS to trusted contacts
    for (final contact in widget.contacts) {
      if (contact.phoneNumber.isNotEmpty) {
        _sendEmergencySMS(contact.phoneNumber);
      }
    }
  }

  Future<void> _sendEmergencySMS(String phone) async {
    final lat = widget.currentLatitude.toStringAsFixed(5);
    final lon = widget.currentLongitude.toStringAsFixed(5);
    final message = Uri.encodeComponent(
      'EMERGENCY ALERT: I need immediate assistance! My live Bengaluru location is: https://maps.google.com/?q=$lat,$lon (SafeTour Alert)',
    );
    final uri = Uri.parse('sms:$phone?body=$message');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _call112() async {
    final uri = Uri(scheme: 'tel', path: AppConstants.policeEmergency);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _cancelAlert() async {
    _timer?.cancel();
    if (_sosEvent != null) {
      await _emergencyRepo.resolveSOSEvent(_sosEvent!.id,
          status: 'false_alarm');
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: Stack(
        children: [
          // Ambient Coral/Red Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    AppColors.error.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Title & Subtitle (Exact Stitch Typography)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        _isDispatched ? 'Alert Dispatched!' : 'SOS Triggered',
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.error,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isDispatched
                            ? 'Your live GPS coordinates have been broadcasted to emergency responders and trusted contacts.'
                            : 'Live location will be sent to emergency services and ${widget.contacts.length} contacts in',
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Center Pulsing Circle (Exact Stitch Visuals)
                  Expanded(
                    child: Center(
                      child: _isDispatched
                          ? _buildDispatchedContent()
                          : _buildCountdownCircle(),
                    ),
                  ),

                  // Bottom Slide to Cancel Slider (Exact Stitch UI)
                  _buildSlideToCancel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCircle() {
    return AnimatedBuilder(
      animation: _pulseScale,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Halo Blur 1
            Transform.scale(
              scale: _pulseScale.value * 1.25,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Outer Halo Blur 2
            Transform.scale(
              scale: _pulseScale.value * 1.1,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
            ),
            // Main Coral Circle with glowing drop shadow
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.55),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: AppTypography.displayLg.copyWith(
                    color: AppColors.onError,
                    fontSize: 84,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDispatchedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.error, width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.warning_amber_rounded,
              size: 68,
              color: AppColors.error,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _call112,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onError,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          icon: const Icon(Icons.call, size: 24),
          label: const Text(
            'Call 112 (Police Emergency)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideToCancel() {
    const double sliderHeight = 76.0;
    const double thumbSize = 60.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - thumbSize - 16;

        return Container(
          width: double.infinity,
          height: sliderHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Centered "Slide to Cancel" label
              Center(
                child: Text(
                  'SLIDE TO CANCEL',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Draggable Thumb Button
              Positioned(
                left: 8 + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition > maxDrag * 0.55) {
                      _cancelAlert();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  onTap: _cancelAlert,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerHighest,
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.onSurface,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
