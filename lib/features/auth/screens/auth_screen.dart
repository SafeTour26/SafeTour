import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../navigation/main_navigation_shell.dart';
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isSignUp = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    try {
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null && mounted) {
          final userEmail = session.user.email;
          if (userEmail != null && userEmail.isNotEmpty) {
            await _profileRepo.saveUserEmail(userEmail);
          }
          await _profileRepo.fetchRemoteProfileIfAvailable();
          final isCompleted = await _profileRepo.isProfileCompleted();
          if (mounted) {
            if (!isCompleted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) =>
                        ProfileSetupScreen(initialEmail: userEmail)),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const MainNavigationShell()),
              );
            }
          }
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        await _profileRepo.saveUserEmail(email);

        if (mounted) {
          if (res.session != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) =>
                      ProfileSetupScreen(initialEmail: email)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Account created! Please check your email for confirmation or sign in.'),
                backgroundColor: AppColors.secondary,
                duration: Duration(seconds: 4),
              ),
            );
            setState(() => _isSignUp = false);
          }
        }
      } else {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.session != null && mounted) {
          await _profileRepo.saveUserEmail(email);
          await _profileRepo.fetchRemoteProfileIfAvailable();
          final isCompleted = await _profileRepo.isProfileCompleted();
          if (mounted) {
            if (!isCompleted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) =>
                        ProfileSetupScreen(initialEmail: email)),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const MainNavigationShell()),
              );
            }
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.safetour://login-callback',
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.safetour://login-callback',
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign-In failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar with Back Arrow and Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Icon(Icons.security_rounded,
                                color: AppColors.primary, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('SafeTour',
                            style: AppTypography.headlineSm
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Heading & Subtitle
                Text(
                  _isSignUp ? 'Create an account' : 'Welcome back',
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Join a safer way to explore the world with real-time incident radar.'
                      : 'Sign in to access your trusted safety circle and verified safe zones.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Segmented Toggle Pill (Sign Up | Sign In)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUp = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _isSignUp
                                  ? AppColors.surfaceContainerHigh
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Center(
                              child: Text(
                                'Sign Up',
                                style: AppTypography.labelMd.copyWith(
                                  color: _isSignUp
                                      ? AppColors.onSurface
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: _isSignUp
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUp = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: !_isSignUp
                                  ? AppColors.surfaceContainerHigh
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: AppTypography.labelMd.copyWith(
                                  color: !_isSignUp
                                      ? AppColors.onSurface
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: !_isSignUp
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Email Input
                Text(
                  'Email',
                  style: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'alex@example.com',
                    prefixIcon:
                        const Icon(Icons.mail_outline_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty || !v.contains('@'))
                          ? 'Please enter a valid email'
                          : null,
                ),
                const SizedBox(height: 18),

                // Password Input
                Text(
                  'Password',
                  style: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: '••••••••••',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter password';
                    }
                    if (_isSignUp && v.length < 6) {
                      return 'Must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Must contain at least 6 characters',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.outline),
                  ),
                ],
                const SizedBox(height: 24),

                // Primary CTA Button (Stitch Emerald Green)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: const Color(0xFF002113),
                      disabledBackgroundColor:
                          AppColors.secondary.withValues(alpha: 0.5),
                      disabledForegroundColor:
                          const Color(0xFF002113).withValues(alpha: 0.7),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF002113)),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Guest option
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _continueAsGuest,
                    child: Text(
                      'Explore directly as Guest',
                      style: AppTypography.bodySm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Or continue with divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.outline,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.5))),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Auth Buttons (Stitch styling)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithApple,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      side: BorderSide(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                    icon: const Icon(Icons.apple_rounded, size: 22),
                    label: const Text('Continue with Apple',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      side: BorderSide(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                    icon: const Icon(Icons.g_mobiledata_rounded,
                        size: 28, color: AppColors.primary),
                    label: const Text('Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),

                // Footer Legal Note
                Center(
                  child: Text(
                    "By continuing, you agree to SafeTour's Terms of Service and Privacy Policy.",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
