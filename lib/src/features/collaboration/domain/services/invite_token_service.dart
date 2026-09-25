import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Service responsible for cryptographically secure invite token generation,
/// SHA-256 hashing, and URL extraction.
class InviteTokenService {
  static final Random _secureRandom = Random.secure();

  InviteTokenService._();

  /// Generates a cryptographically secure, high-entropy 32-byte hex token.
  static String generateSecureToken() {
    final values = List<int>.generate(32, (i) => _secureRandom.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Calculates the SHA-256 hash of an invite token.
  ///
  /// Only this hash is sent and stored in the database, never the raw token.
  static String hashToken(String token) {
    final bytes = utf8.encode(token.trim());
    return sha256.convert(bytes).toString();
  }

  /// Builds the deep link URL for an invite token.
  static String buildInviteUrl(String token) {
    return 'https://listix.app/join/${token.trim()}';
  }

  /// Extracts the invite token from a full URL or direct token string.
  ///
  /// Supports:
  /// - `https://listix.app/join/<token>`
  /// - `listix://join/<token>`
  /// - `<token>`
  static String? extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('/join/')) {
      final parts = trimmed.split('/join/');
      if (parts.length > 1) {
        final tokenPart = parts[1].split('?').first.split('#').first.trim();
        if (tokenPart.isNotEmpty) return tokenPart;
      }
    }

    try {
      final uri = Uri.parse(trimmed);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last.trim();
        if (last.isNotEmpty && last != 'join') {
          return last;
        }
      }
    } catch (_) {}

    return trimmed;
  }
}
