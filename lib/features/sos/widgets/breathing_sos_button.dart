import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class BreathingSOSButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const BreathingSOSButton({
    super.key,
    required this.onTap,
    this.size = 76,
  });

  @override
  State<BreathingSOSButton> createState() => _BreathingSOSButtonState();
}

class _BreathingSOSButtonState extends State<BreathingSOSButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // BoxShadow pulsing between 12px and 36px blur (per design.md)
    _glowAnimation = Tween<double>(begin: 12.0, end: 36.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final blur = _glowAnimation.value;
        final scale = _scaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.45),
                  blurRadius: blur,
                  spreadRadius: 2.0,
                ),
                BoxShadow(
                  color: AppColors.errorContainer.withValues(alpha: 0.6),
                  blurRadius: blur * 0.6,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFC02A24),
                        AppColors.errorContainer,
                      ],
                      center: Alignment(-0.2, -0.3),
                      radius: 0.9,
                    ),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emergency_rounded,
                          color: AppColors.onErrorContainer,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SOS',
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.onErrorContainer,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
