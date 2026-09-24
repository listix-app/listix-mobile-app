import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/theme/app_colors.dart';
import 'package:listix/src/core/theme/app_theme.dart';
import 'package:listix/src/features/ads/data/ad_config.dart';
import 'package:listix/src/routing/routes.dart';

void main() {
  group('AppColors & Theme', () {
    test('AppColors values are correctly defined', () {
      expect(AppColors.primary, const Color(0xFF0D9488));
      expect(AppColors.primaryDark, const Color(0xFF0F766E));
      expect(AppColors.primaryLight, const Color(0xFFCCFBF1));
      expect(AppColors.primarySubtle, const Color(0xFFF0FDFA));
      expect(AppColors.onPrimary, Colors.white);
      expect(AppColors.surfaceLight, const Color(0xFFF8FAFC));
      expect(AppColors.cardLight, Colors.white);
      expect(AppColors.borderLight, const Color(0xFFE2E8F0));
      expect(AppColors.borderFocus, const Color(0xFF0D9488));
      expect(AppColors.surfaceDark, const Color(0xFF0F172A));
      expect(AppColors.cardDark, const Color(0xFF1E293B));
      expect(AppColors.borderDark, const Color(0xFF334155));
      expect(AppColors.textPrimaryDark, const Color(0xFFF8FAFC));
      expect(AppColors.textSecondaryDark, const Color(0xFF94A3B8));
      expect(AppColors.textMutedDark, const Color(0xFF64748B));
      expect(AppColors.textPrimary, const Color(0xFF0F172A));
      expect(AppColors.textSecondary, const Color(0xFF475569));
      expect(AppColors.textMuted, const Color(0xFF64748B));
      expect(AppColors.syncPending, const Color(0xFFF59E0B));
      expect(AppColors.syncPendingSubtle, const Color(0xFFFEF3C7));
      expect(AppColors.syncDone, const Color(0xFF10B981));
      expect(AppColors.syncDoneSubtle, const Color(0xFFD1FAE5));
      expect(AppColors.offline, const Color(0xFF64748B));
      expect(AppColors.offlineSubtle, const Color(0xFFF1F5F9));
      expect(AppColors.delete, const Color(0xFFDC2626));
      expect(AppColors.deleteBackground, const Color(0xFFFEE2E2));
    });

    test('AppTheme generates light theme with required component styles', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.surfaceLight);
      expect(theme.cardTheme.elevation, 0);
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        AppColors.primary,
      );
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.dividerTheme.color, AppColors.borderLight);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });

    test('AppTheme generates dark theme with required component styles', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.surfaceDark);
      expect(theme.cardTheme.elevation, 0);
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        AppColors.primary,
      );
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.dividerTheme.color, AppColors.borderDark);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });
  });

  group('AppRoutes & AdConfig', () {
    test('AppRoutes helper paths format correctly', () {
      expect(AppRoutes.home, '/');
      expect(AppRoutes.newList, '/lists/new');
      expect(AppRoutes.listDetail, '/list/:id');
      expect(AppRoutes.editList, '/list/:id/edit');
      expect(AppRoutes.settings, '/settings');
      expect(AppRoutes.about, '/about');

      expect(AppRoutes.listDetailPath('list-123'), '/list/list-123');
      expect(AppRoutes.editListPath('list-456'), '/list/list-456/edit');
    });

    test('AdConfig provides valid banner unit id', () {
      expect(AdConfig.bannerId, isNotEmpty);
      expect(AdConfig.bannerId, 'ca-app-pub-3940256099942544/6300978111');
    });
  });
}
