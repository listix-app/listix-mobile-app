import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class InviteTokenService {
  static final Random _secureRandom = Random.secure();

  InviteTokenService._(); // coverage:ignore-line

  static String generateSecureToken() {
    final values = List<int>.generate(32, (i) => _secureRandom.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String hashToken(String token) {
    final bytes = utf8.encode(token.trim());
    return sha256.convert(bytes).toString();
  }

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
