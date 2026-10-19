import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/models/sos_event.dart';
import '../../../data/repositories/emergency_repository.dart';

class ActiveSOSDialog extends StatefulWidget {
  final String userId;
  final double currentLatitude;
  final double currentLongitude;
  final List<EmergencyContact> contacts;

  const ActiveSOSDialog({
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
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActiveSOSDialog(
        userId: userId,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        contacts: contacts,
      ),
    );
  }

  @override
  State<ActiveSOSDialog> createState() => _ActiveSOSDialogState();
}

class _ActiveSOSDialogState extends State<ActiveSOSDialog> {
  final EmergencyRepository _emergencyRepo = EmergencyRepository();
  int _countdown = 3;
  Timer? _timer;
  bool _isDispatched = false;
  SOSEvent? _sosEvent;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _dispatchEmergencySOS();
      }
    });
  }

  Future<void> _dispatchEmergencySOS() async {
    setState(() {
      _countdown = 0;
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
  }

  Future<void> _callHelpline(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmergencySMS(String phone) async {
    final lat = widget.currentLatitude.toStringAsFixed(5);
    final lon = widget.currentLongitude.toStringAsFixed(5);
    final message = Uri.encodeComponent(
      'EMERGENCY ALERT: I need immediate assistance! My live Bengaluru location is: https://maps.google.com/?q=$lat,$lon (via SafeTour app)',
    );
    final uri = Uri.parse('sms:$phone?body=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _cancelOrResolve(String status) async {
    _timer?.cancel();
    if (_sosEvent != null) {
      await _emergencyRepo.resolveSOSEvent(_sosEvent!.id, status: status);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'false_alarm'
                ? 'SOS alert cancelled (marked as false alarm).'
                : 'Emergency event resolved.',
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing Header Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _countdown > 0
                        ? Text(
                            '$_countdown',
                            style: AppTypography.displayLg.copyWith(
                              color: AppColors.error,
                              fontSize: 32,
                            ),
                          )
                        : const Icon(
                            Icons.emergency_rounded,
                            color: AppColors.error,
                            size: 38,
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  _countdown > 0
                      ? 'Triggering Emergency Alert'
                      : 'ACTIVE EMERGENCY SOS',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  _countdown > 0
                      ? 'Dispatching coordinates to Supabase in $_countdown seconds...'
                      : 'Coordinates logged: ${widget.currentLatitude.toStringAsFixed(4)}, ${widget.currentLongitude.toStringAsFixed(4)}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Immediate Call Options
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _callHelpline(AppConstants.policeEmergency),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorContainer,
                          foregroundColor: AppColors.onErrorContainer,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 20),
                        label: const Text(
                          'Dial 112',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _callHelpline(AppConstants.womenHelpline),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.support_agent_rounded, size: 20),
                        label: const Text(
                          'Call 1091',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Emergency Contacts Quick Trigger
                if (widget.contacts.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contacts Alert',
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        ...widget.contacts.take(2).map((contact) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    contact.contactName,
                                    style: AppTypography.labelLg,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (contact.contactPhone != null &&
                                    contact.contactPhone!.isNotEmpty) ...[
                                  IconButton(
                                    icon: const Icon(Icons.sms_rounded,
                                        color: AppColors.secondary, size: 20),
                                    onPressed: () => _sendEmergencySMS(
                                        contact.contactPhone!),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call_rounded,
                                        color: AppColors.primary, size: 20),
                                    onPressed: () =>
                                        _callHelpline(contact.contactPhone!),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // False Alarm / Resolve buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelOrResolve('false_alarm'),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: AppColors.outlineVariant),
                        ),
                        child: const Text('Cancel / False Alarm'),
                      ),
                    ),
                    if (_isDispatched) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _cancelOrResolve('resolved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryContainer,
                            foregroundColor: AppColors.onSecondaryContainer,
                          ),
                          child: const Text('I am Safe Now'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
