class SupabaseConstants {
  /// Supabase project URL loaded via `--dart-define-from-file=.env` or `--dart-define=SUPABASE_URL=...`
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://egvfpjasmojxuataajeb.supabase.co',
  );

  /// Supabase public anon key loaded via `--dart-define-from-file=.env` or `--dart-define=SUPABASE_ANON_KEY=...`
  /// Team members can configure their key in .env or pass it at build/run time.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Helper flag to verify if a valid Supabase configuration is present
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
