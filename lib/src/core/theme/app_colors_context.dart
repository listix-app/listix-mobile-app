import 'package:flutter/material.dart';

import 'app_colors.dart';

extension AppSurfaceColors on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  Color get cardSurface => isDarkTheme ? AppColors.cardDark : Colors.white;

  Color get borderColor =>
      isDarkTheme ? AppColors.borderDark : AppColors.borderLight;

  Color get mutedTextColor =>
      isDarkTheme ? AppColors.textMutedDark : AppColors.textMuted;

  Color get surfaceColor =>
      isDarkTheme ? AppColors.surfaceDark : AppColors.surfaceLight;
}
