// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service managing Supabase initialization, invisible anonymous authentication,
/// and client access.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _initialized = false;
  bool _anonymousAuthDisabled = false;
  SupabaseClient? _customClient;

  /// Injected client for unit testing or overrides.
  @visibleForTesting
  set testClient(SupabaseClient? client) {
    _customClient = client;
    _initialized = client != null;
    _anonymousAuthDisabled = false;
  }

  /// Whether Supabase has been initialized successfully.
  bool get isReady => _initialized && client != null && !_anonymousAuthDisabled;

  /// Supabase client instance. Returns null if not initialized or configured.
  SupabaseClient? get client {
    if (_customClient != null) {
      return _customClient;
    }
    if (!_initialized) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// The currently authenticated user's ID (anonymous or registered).
  String? get currentUserId => client?.auth.currentUser?.id;

  /// Initialize Supabase and authenticate anonymously in the background without UI login.
  Future<void> initialize({String? url, String? anonKey}) async {
    final effectiveUrl = (url ?? SupabaseConfig.supabaseUrl).trim();
    final effectiveKey = (anonKey ?? SupabaseConfig.supabaseAnonKey).trim();
    _anonymousAuthDisabled = false;

    if (effectiveUrl.isEmpty || effectiveKey.isEmpty) {
      debugPrint(
        '[SupabaseService] No credentials provided, running in local-only mode.',
      );
      _initialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: effectiveUrl,
        publishableKey: effectiveKey,
      );
      _initialized = true;

      // Invisible Anonymous Auth: ensure user has an active session without any login prompt.
      try {
        await ensureAnonymousAuth();
      } catch (e) {
        debugPrint('[SupabaseService] Anonymous auth unavailable: $e');
      }
    } catch (e, stack) {
      debugPrint('[SupabaseService] Initialization failed: $e\n$stack');
      _initialized = false;
    }
  }

  /// Ensures an anonymous user session exists. Does not show any UI to the user.
  Future<String?> ensureAnonymousAuth() async {
    final cli = client;
    if (cli == null) return null;
    if (_anonymousAuthDisabled) {
      throw StateError('Anonymous Sign-Ins está deshabilitado en Supabase.');
    }

    try {
      final user = cli.auth.currentUser;
      if (user != null) {
        return user.id;
      }

      final response = await cli.auth.signInAnonymously();
      final userId = response.user?.id;
      if (userId == null) {
        throw StateError('Supabase no creó una sesión anónima.');
      }
      return userId;
    } catch (e) {
      if (e.toString().contains('anonymous_provider_disabled')) {
        _anonymousAuthDisabled = true;
        debugPrint(
          '[SupabaseService] Activa Anonymous Sign-Ins en Authentication > Providers > Anonymous Sign-Ins del proyecto Supabase.',
        );
      }
      debugPrint('[SupabaseService] Anonymous authentication failed: $e');
      final currentUserId = cli.auth.currentUser?.id;
      if (currentUserId != null) return currentUserId;
      rethrow;
    }
  }
}

/// Riverpod provider exposing the [SupabaseService] singleton.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

/// Riverpod provider exposing the optional [SupabaseClient].
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return ref.watch(supabaseServiceProvider).client;
});
