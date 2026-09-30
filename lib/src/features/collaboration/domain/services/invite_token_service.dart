import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class InviteTokenService {
  static final Random _secureRandom = Random.secure();
  static const String _codeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static final RegExp _inviteCodeRegex = RegExp(r'^[A-Za-z0-9]{8}$');

  InviteTokenService._(); // coverage:ignore-line

  /// Generates an internal secure 256-bit random hex token.
  static String generateSecureToken() {
    final values = List<int>.generate(32, (i) => _secureRandom.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generates a user-friendly 8-character alphanumeric invite code (e.g. K7M4XP2Q).
  static String generateInviteCode() {
    final chars = List<String>.generate(8, (_) {
      final index = _secureRandom.nextInt(_codeAlphabet.length);
      return _codeAlphabet[index];
    });
    return chars.join();
  }

  /// Returns true if [code] matches the 8-character alphanumeric invite code format.
  static bool isInviteCode(String code) {
    return _inviteCodeRegex.hasMatch(code.trim());
  }

  /// Computes the SHA-256 hash of [token].
  static String hashToken(String token) {
    final bytes = utf8.encode(token.trim());
    return sha256.convert(bytes).toString();
  }

  /// Extracts the invite code or token from a URL, custom URI scheme, or raw input.
  static String? extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    String candidate = trimmed;

    if (trimmed.contains('/join/')) {
      final parts = trimmed.split('/join/');
      if (parts.length > 1) {
        final tokenPart = parts[1].split('?').first.split('#').first.trim();
        if (tokenPart.isNotEmpty) {
          candidate = tokenPart;
        }
      }
    } else {
      try {
        final uri = Uri.parse(trimmed);
        if (uri.pathSegments.isNotEmpty) {
          final last = uri.pathSegments.last.trim();
          if (last.isNotEmpty && last != 'join') {
            candidate = last;
          }
        }
      } catch (_) {}
    }

    final cleanCandidate = candidate
        .replaceAll(RegExp(r'^/+'), '')
        .split('/')
        .last
        .trim();
    if (isInviteCode(cleanCandidate)) {
      return cleanCandidate.toUpperCase();
    }
    return cleanCandidate.isNotEmpty ? cleanCandidate : null;
  }
}
