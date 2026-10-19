import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/screens/auth_screen.dart';
import '../../navigation/main_navigation_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = const [
    {
      'icon': Icons.security_rounded,
      'iconColor': AppColors.primary,
      'title': 'Travel with peace of mind.',
      'description':
          'SafeTour provides real-time safety insights and instant emergency support wherever you are.',
    },
    {
      'icon': Icons.emergency_rounded,
      'iconColor': AppColors.error,
      'title': 'SOS Emergency Trigger.',
      'description':
          'One-tap discreet alert dispatches your coordinates to local responders and designated safety contacts.',
    },
    {
      'icon': Icons.share_location_rounded,
      'iconColor': AppColors.secondary,
      'title': 'Live Sharing.',
      'description':
          'Keep loved ones updated automatically with encrypted live trip tracking and arrival check-ins.',
    },
    {
      'icon': Icons.map_rounded,
      'iconColor': AppColors.tertiary,
      'title': 'Safety Heatmap.',
      'description':
          'Navigate safely with crowd-sourced nighttime lighting scores, crowd density, and verified safe zones.',
    },
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  Future<void> _markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('safetour_onboarding_completed', true);
    } catch (_) {}
  }

  Future<void> _navigateToAuth() async {
    await _markOnboardingCompleted();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  Future<void> _skipToApp() async {
    await _markOnboardingCompleted();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapHeight =
                (constraints.maxHeight * 0.22).clamp(110.0, 190.0);
            return Column(
              children: [
                // Top App Bar with Skip Action
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SafeTour',
                            style: AppTypography.headlineMd.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _skipToApp,
                        child: Text(
                          'Explore App',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Decorative Vector Map Art (Responsive)
                Container(
                  height: mapHeight,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: _OnboardingMapArtPainter(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Dot Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Carousel Slide Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (slide['iconColor'] as Color)
                                        .withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: (slide['iconColor'] as Color)
                                          .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    slide['icon'] as IconData,
                                    size: 24,
                                    color: slide['iconColor'] as Color,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  slide['title'] as String,
                                  style: AppTypography.displayLg.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  slide['description'] as String,
                                  style: AppTypography.bodyLg.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.4,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Buttons (Next & Skip)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            foregroundColor: AppColors.onSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: const BorderSide(
                                  color: AppColors.outlineVariant),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _navigateToAuth,
                        child: Text(
                          'Skip to Sign In',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingMapArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF75DAA8).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Simulated grid roads
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x + 20, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 35) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 10), linePaint);
    }

    // Glowing main neon route
    final path = Path()
      ..moveTo(20, size.height * 0.8)
      ..lineTo(size.width * 0.3, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.45)
      ..lineTo(size.width * 0.8, size.height * 0.2);

    final glowPaint = Paint()
      ..color = const Color(0xFF75DAA8).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final corePaint = Paint()
      ..color = const Color(0xFF75DAA8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
