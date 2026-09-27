class SupabaseConfig {
  const SupabaseConfig._(); // coverage:ignore-line

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String inviteBaseUrl = String.fromEnvironment(
    'INVITE_BASE_URL',
    defaultValue: 'https://example.invalid/join',
  );

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty && // coverage:ignore-line
      !supabaseUrl.contains('YOUR_SUPABASE') && // coverage:ignore-line
      !supabaseAnonKey.contains('YOUR_SUPABASE'); // coverage:ignore-line
}
