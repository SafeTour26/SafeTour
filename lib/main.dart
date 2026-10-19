import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/profile_setup_screen.dart';
import 'features/navigation/main_navigation_shell.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surfaceContainerLowest,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize Supabase (loads credentials from .env via --dart-define-from-file=.env)
  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConstants.anonKey.isNotEmpty
          ? SupabaseConstants.anonKey
          : 'offline-placeholder-key',
    );
  } catch (e) {
    debugPrint('Supabase initialization warning (running in offline mode): $e');
  }

  runApp(const SafeTourApp());
}

class SafeTourApp extends StatelessWidget {
  const SafeTourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeTour',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppGate(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  final ProfileRepository _profileRepo = ProfileRepository();
  late final Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();
    _initialScreenFuture = _resolveInitialScreen();
  }

  Future<Widget> _resolveInitialScreen() async {
    try {
      if (SupabaseConstants.isConfigured) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final email = session.user.email;
          if (email != null && email.isNotEmpty) {
            await _profileRepo.saveUserEmail(email);
          }
          await _profileRepo.fetchRemoteProfileIfAvailable();
          final isComplete = await _profileRepo.isProfileCompleted();
          if (!isComplete) {
            return ProfileSetupScreen(initialEmail: email);
          }
          return const MainNavigationShell();
        }
      }

      // If no active session, check if onboarding was previously finished
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool('safetour_onboarding_completed') ?? false;

      if (onboardingDone) {
        return SupabaseConstants.isConfigured
            ? const AuthScreen()
            : const MainNavigationShell();
      } else {
        return const OnboardingScreen();
      }
    } catch (e) {
      debugPrint('AppGate resolution error: $e');
      return const OnboardingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.security_rounded,
                        color: AppColors.primary, size: 30),
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
