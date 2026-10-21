import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

class AuthSessionService {
  static final AuthSessionService instance = AuthSessionService();

  final FlutterSecureStorage _storage;
  final http.Client _httpClient;
  bool _initialized;

  static const _accessTokenKey = 'listix_access_token';
  static const _refreshTokenKey = 'listix_refresh_token';
  static const _userIdKey = 'listix_user_id';
  static const _expiresAtKey = 'listix_access_token_expires_at';

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedUserId;
  DateTime? _cachedExpiresAt;

  final bool Function()? _isConfigured;

  AuthSessionService({
    FlutterSecureStorage? storage,
    http.Client? httpClient,
    bool initialized = false,
    bool Function()? isConfigured,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _httpClient = httpClient ?? http.Client(),
       _initialized = initialized,
       _isConfigured = isConfigured;

  @visibleForTesting
  set testInitialized(bool value) {
    _initialized = value;
  }

  @visibleForTesting
  ApiException parseErrorForTest(http.Response response) =>
      _parseError(response);

  bool get _configured => _isConfigured?.call() ?? ApiConfig.isConfigured;

  bool get isReady => _initialized && _configured;

  String? get currentUserId => _cachedUserId;

  Future<void> initialize() async {
    if (!_configured) {
      _initialized = false;
      return;
    }
    await _loadFromStorage();
    if (_cachedAccessToken == null || _cachedRefreshToken == null) {
      await authenticateAnonymously();
      _initialized = true;
      return;
    }
    if (_isExpiringSoon()) {
      await refreshTokens();
    }
    _initialized = true;
  }

  Future<void> ensureInitialized() async {
    if (!_configured) {
      _initialized = false;
      return;
    }
    if (_initialized) {
      return;
    }
    try {
      await initialize();
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    if (!isReady) {
      return null;
    }
    if (_cachedAccessToken == null) {
      await _loadFromStorage();
    }
    if (_cachedAccessToken == null) {
      await authenticateAnonymously();
      return _cachedAccessToken;
    }
    if (_isExpiringSoon()) {
      await refreshTokens();
    }
    return _cachedAccessToken;
  }

  Future<String?> getUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId;
    }
    await _loadFromStorage();
    if (_cachedUserId != null) {
      return _cachedUserId;
    }
    if (isReady) {
      await authenticateAnonymously();
    }
    return _cachedUserId;
  }

  Future<void> authenticateAnonymously() async {
    if (!_configured) {
      return;
    }
    final url = Uri.parse('${ApiConfig.restBaseUrl}/auth/anonymous');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _initialized = true;
      await _saveSession(data);
    } else {
      throw _parseError(response);
    }
  }

  Future<bool> refreshTokens() async {
    if (!_configured) {
      return false;
    }
    if (_cachedRefreshToken == null) {
      await _loadFromStorage();
    }
    final refreshToken = _cachedRefreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await authenticateAnonymously();
      return true;
    }

    final url = Uri.parse('${ApiConfig.restBaseUrl}/auth/refresh');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _initialized = true;
      await _saveSession(data);
      return true;
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 404) {
      await clearSession();
      await authenticateAnonymously();
      return true;
    }

    throw _parseError(response);
  }

  Future<void> clearSession() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserId = null;
    _cachedExpiresAt = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _expiresAtKey);
  }

  bool _isExpiringSoon() {
    if (_cachedExpiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(
      _cachedExpiresAt!.subtract(const Duration(seconds: 60)),
    );
  }

  Future<void> _loadFromStorage() async {
    _cachedAccessToken = await _storage.read(key: _accessTokenKey);
    _cachedRefreshToken = await _storage.read(key: _refreshTokenKey);
    _cachedUserId = await _storage.read(key: _userIdKey);
    final expiresAtStr = await _storage.read(key: _expiresAtKey);
    if (expiresAtStr != null) {
      _cachedExpiresAt = DateTime.tryParse(expiresAtStr);
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _cachedUserId = data['userId'] as String?;
    _cachedAccessToken = data['accessToken'] as String?;
    _cachedRefreshToken = data['refreshToken'] as String?;
    final expiresIn = (data['accessTokenExpiresIn'] as num?)?.toInt() ?? 900;
    _cachedExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    if (_cachedAccessToken != null) {
      await _storage.write(key: _accessTokenKey, value: _cachedAccessToken!);
    }
    if (_cachedRefreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: _cachedRefreshToken!);
    }
    if (_cachedUserId != null) {
      await _storage.write(key: _userIdKey, value: _cachedUserId!);
    }
    if (_cachedExpiresAt != null) {
      await _storage.write(
        key: _expiresAtKey,
        value: _cachedExpiresAt!.toIso8601String(),
      );
    }
  }

  ApiException _parseError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final errorCode = json['errorCode'] as String?;
      final message =
          (json['message'] as String?) ??
          response.reasonPhrase ??
          'Request failed';
      return ApiException(
        statusCode: response.statusCode,
        errorCode: errorCode,
        message: message,
      );
    } catch (_) {
      return ApiException(
        statusCode: response.statusCode,
        message: response.reasonPhrase ?? 'Request failed',
      );
    }
  }
}

final authSessionServiceProvider = Provider<AuthSessionService>((ref) {
  return AuthSessionService.instance;
});
