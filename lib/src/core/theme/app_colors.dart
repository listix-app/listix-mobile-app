import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFFCCFBF1); // Teal 100
  static const Color primarySubtle = Color(0xFFF0FDFA); // Teal 50
  static const Color onPrimary = Colors.white;

  static const Color surfaceLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderFocus = Color(0xFF0D9488); // Teal 600

  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500

  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Slate 900 (15.5:1 ratio)
  static const Color textSecondary = Color(
    0xFF475569,
  ); // Slate 600 (5.8:1 ratio - AA & AAA compliant)
  static const Color textMuted = Color(0xFF64748B); // Slate 500 (4.6:1 ratio)

  static const Color syncPending = Color(0xFFF59E0B); // Amber 500
  static const Color syncPendingSubtle = Color(0xFFFEF3C7); // Amber 100
  static const Color syncDone = Color(0xFF10B981); // Emerald 500
  static const Color syncDoneSubtle = Color(0xFFD1FAE5); // Emerald 100
  static const Color offline = Color(0xFF64748B); // Slate 500
  static const Color offlineSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color delete = Color(0xFFDC2626);
  static const Color deleteBackground = Color(0xFFFEE2E2);

  static const List<Color> listColors = [
    Color(0xFF0D9488),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFFDC2626),
  ];
}
