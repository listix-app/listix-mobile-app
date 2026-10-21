import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'auth_session_service.dart';

class ApiClient {
  final http.Client _httpClient;
  final AuthSessionService _authSession;

  ApiClient({http.Client? httpClient, AuthSessionService? authSession})
    : _httpClient = httpClient ?? http.Client(),
      _authSession = authSession ?? AuthSessionService.instance;

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _sendWithRetry(
      method,
      path,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return request(
      'GET',
      path,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
  }) {
    return request(
      'POST',
      path,
      headers: headers,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
  }) {
    return request(
      'PUT',
      path,
      headers: headers,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
  }) {
    return request(
      'PATCH',
      path,
      headers: headers,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return request(
      'DELETE',
      path,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${ApiConfig.restBaseUrl}$cleanPath';
    final baseUri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }
    final stringParams = queryParameters.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    return baseUri.replace(queryParameters: stringParams);
  }

  Future<http.Response> _sendWithRetry(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    var response = await _sendSingle(
      method,
      uri,
      headers: headers,
      body: body,
      requiresAuth: requiresAuth,
    );

    if (response.statusCode == 401 && requiresAuth) {
      try {
        final refreshed = await _authSession.refreshTokens();
        if (refreshed) {
          response = await _sendSingle(
            method,
            uri,
            headers: headers,
            body: body,
            requiresAuth: requiresAuth,
          );
        }
      } catch (_) {}
    }

    return response;
  }

  Future<http.Response> _sendSingle(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
  }) async {
    final requestHeaders = Map<String, String>.from(headers ?? {});

    if (requiresAuth) {
      final token = await _authSession.getAccessToken();
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    String? encodedBody;
    if (body != null) {
      if (!requestHeaders.containsKey('Content-Type')) {
        requestHeaders['Content-Type'] = 'application/json';
      }
      if (body is String) {
        encodedBody = body;
      } else {
        encodedBody = jsonEncode(body);
      }
    }

    switch (method.toUpperCase()) {
      case 'GET':
        return _httpClient.get(uri, headers: requestHeaders);
      case 'POST':
        return _httpClient.post(
          uri,
          headers: requestHeaders,
          body: encodedBody,
        );
      case 'PUT':
        return _httpClient.put(uri, headers: requestHeaders, body: encodedBody);
      case 'PATCH':
        return _httpClient.patch(
          uri,
          headers: requestHeaders,
          body: encodedBody,
        );
      case 'DELETE':
        return _httpClient.delete(
          uri,
          headers: requestHeaders,
          body: encodedBody,
        );
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  ApiException parseError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final errorCode = json['errorCode'] as String?;
      final message =
          (json['message'] as String?) ??
          response.reasonPhrase ??
          'Request failed with status ${response.statusCode}';
      return ApiException(
        statusCode: response.statusCode,
        errorCode: errorCode,
        message: message,
      );
    } catch (_) {
      return ApiException(
        statusCode: response.statusCode,
        message:
            response.reasonPhrase ??
            'Request failed with status ${response.statusCode}',
      );
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final authSession = ref.watch(authSessionServiceProvider);
  return ApiClient(authSession: authSession);
});
