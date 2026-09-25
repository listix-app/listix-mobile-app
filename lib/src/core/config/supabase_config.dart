/// Configuration for Supabase credentials and environments.
///
/// Can be supplied at build time using `--dart-define`:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// or configured at runtime.
class SupabaseConfig {
  const SupabaseConfig._(); // coverage:ignore-line

  /// The Supabase Project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// The Supabase anonymous/public API key (anon key).
  ///
  /// IMPORTANT: Never expose the Supabase service-role key in Flutter!
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String inviteBaseUrl = String.fromEnvironment(
    'INVITE_BASE_URL',
    defaultValue: 'https://example.invalid/join',
  );

  /// Whether Supabase configuration is present and non-empty.
  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty && // coverage:ignore-line
      !supabaseUrl.contains('YOUR_SUPABASE') && // coverage:ignore-line
      !supabaseAnonKey.contains('YOUR_SUPABASE'); // coverage:ignore-line
}
