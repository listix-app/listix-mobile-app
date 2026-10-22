import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String defaultProdUrl = 'https://listix-worker.onrender.com';
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  @visibleForTesting
  static String? testBaseUrl;

  static bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static String get effectiveBaseUrl {
    if (testBaseUrl != null) return testBaseUrl!;
    final configured = apiBaseUrl.trim();
    if (configured.isNotEmpty) return configured;
    if (_isTestEnvironment) return '';
    return defaultProdUrl;
  }

  static String normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String get normalizedBaseUrl => normalizeUrl(effectiveBaseUrl);

  static String get restBaseUrl => '$normalizedBaseUrl/api/v1';

  static String get realtimeNamespace => '/realtime';

  static bool get isConfigured =>
      effectiveBaseUrl.trim().isNotEmpty &&
      !effectiveBaseUrl.contains('YOUR_API_BASE_URL');
}
