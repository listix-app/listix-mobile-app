abstract final class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://listix-worker.onrender.com',
  );

  static String normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String get normalizedBaseUrl => normalizeUrl(apiBaseUrl);

  static String get restBaseUrl => '$normalizedBaseUrl/api/v1';

  static String get realtimeNamespace => '/realtime';

  static bool get isConfigured =>
      apiBaseUrl.trim().isNotEmpty && !apiBaseUrl.contains('YOUR_API_BASE_URL');
}
