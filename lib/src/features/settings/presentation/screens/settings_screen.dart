import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/listix_logo.dart';
import '../../../../routing/routes.dart';
import '../../../lists/presentation/controllers/list_layout_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../security/presentation/controllers/app_lock_controller.dart';

class SettingsScreen extends ConsumerWidget {
  final bool showBuyCoffee;
  final bool showRateApp;

  const SettingsScreen({
    super.key,
    this.showBuyCoffee = false,
    this.showRateApp = false,
  });

  static const String coffeeUrl = 'https://buymeacoffee.com/nmenag';
  static const String feedbackEmail = 'nmena.garzon@gmail.com';
  static const String storeUrl =
      'https://play.google.com/store/apps/details?id=com.nmenag.listix';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final localeNotifier = ref.read(localeControllerProvider.notifier);
    final currentThemeMode = ref.watch(themeModeControllerProvider);
    final themeNotifier = ref.read(themeModeControllerProvider.notifier);
    final notifState = ref.watch(notificationsControllerProvider);
    final lockState = ref.watch(appLockControllerProvider);
    final layoutMode = ref.watch(listLayoutControllerProvider);
    final layoutNotifier = ref.read(listLayoutControllerProvider.notifier);
    final urlService = ref.read(urlLauncherServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSubColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          Center(
            child: Column(
              children: [
                const ListixLogo(size: 64),
                const SizedBox(height: 12),
                Text(
                  'Listix',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: textTitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tr.version} 1.0.0',
                  style: TextStyle(fontSize: 13, color: textSubColor),
                ),
                const SizedBox(height: 4),
                Text(
                  tr.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: textSubColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _SettingsSectionTitle(title: tr.layoutTitle),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<ListLayoutMode>(
                key: const Key('layout_segmented_button'),
                segments: [
                  ButtonSegment<ListLayoutMode>(
                    value: ListLayoutMode.list,
                    label: Text(tr.layoutList),
                    icon: const Icon(Icons.view_agenda_outlined),
                  ),
                  ButtonSegment<ListLayoutMode>(
                    value: ListLayoutMode.grid,
                    label: Text(tr.layoutGrid),
                    icon: const Icon(Icons.grid_view_rounded),
                  ),
                ],
                selected: {layoutMode},
                onSelectionChanged: (Set<ListLayoutMode> newSelection) {
                  layoutNotifier.setLayoutMode(newSelection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SettingsSectionTitle(title: tr.themeTitle),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text(tr.themeSystem),
                        icon: const Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text(tr.themeLight),
                        icon: const Icon(Icons.wb_sunny_rounded),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text(tr.themeDark),
                        icon: const Icon(Icons.nightlight_round),
                      ),
                    ],
                    selected: {currentThemeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      themeNotifier.setThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SettingsSectionTitle(title: tr.languageTitle),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: 'es', label: Text('Español')),
                  ButtonSegment<String>(value: 'en', label: Text('English')),
                ],
                selected: {locale.languageCode},
                onSelectionChanged: (Set<String> newSelection) {
                  final code = newSelection.first;
                  localeNotifier.setLanguage(
                    code == 'en' ? AppLanguage.en : AppLanguage.es,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SettingsSectionTitle(title: tr.notificationsTitle),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: SwitchListTile.adaptive(
              key: const Key('notification_switch'),
              value: notifState.isEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
              inactiveThumbColor: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryDark,
              inactiveTrackColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.borderLight,
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  );
                }
                return null;
              }),
              onChanged: (bool value) {
                ref
                    .read(notificationsControllerProvider.notifier)
                    .toggleNotifications(value);
              },
              title: Text(
                tr.notificationsTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textTitleColor,
                ),
              ),
              subtitle: Text(
                tr.notificationsSubtitle,
                style: TextStyle(fontSize: 12, color: textSubColor),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notifState.isEnabled
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  notifState.isEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  color: notifState.isEnabled
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textMuted),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SettingsSectionTitle(title: tr.appLock),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: SwitchListTile.adaptive(
              key: const Key('app_lock_switch'),
              value: lockState.isEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
              inactiveThumbColor: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryDark,
              inactiveTrackColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.borderLight,
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  );
                }
                return null;
              }),
              onChanged: (bool value) async {
                final success = await ref
                    .read(appLockControllerProvider.notifier)
                    .toggleAppLock(
                      enabled: value,
                      localizedReason: tr.appLockReason,
                    );
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr.errorPrefix('Authentication failed')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              title: Text(
                tr.appLock,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textTitleColor,
                ),
              ),
              subtitle: Text(
                tr.appLockSubtitle,
                style: TextStyle(fontSize: 12, color: textSubColor),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lockState.isEnabled
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  lockState.isEnabled
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  color: lockState.isEnabled
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textMuted),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SettingsSectionTitle(title: tr.backupAndExport),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              key: const Key('settings_backup_and_export_tile'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.backup_table_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                tr.backupAndExport,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textTitleColor,
                ),
              ),
              subtitle: Text(
                tr.backupAndExportSubtitle,
                style: TextStyle(fontSize: 12, color: textSubColor),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: () => context.push(AppRoutes.backup),
            ),
          ),
          const SizedBox(height: 24),

          _SettingsSectionTitle(title: tr.supportAndFeedback),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Column(
              children: [
                if (showBuyCoffee) ...[
                  ListTile(
                    key: const Key('settings_buy_coffee'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF813F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.coffee_rounded,
                        color: Color(0xFFFF813F),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      tr.buyMeACoffee,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textTitleColor,
                      ),
                    ),
                    subtitle: Text(
                      tr.buyMeACoffeeSubtitle,
                      style: TextStyle(fontSize: 12, color: textSubColor),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => urlService.openUrl(coffeeUrl),
                  ),
                  Divider(height: 1, color: borderColor),
                ],
                ListTile(
                  key: const Key('settings_send_feedback'),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.feedback_outlined,
                      color: Color(0xFF6366F1),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    tr.sendFeedback,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textTitleColor,
                    ),
                  ),
                  subtitle: Text(
                    tr.sendFeedbackSubtitle,
                    style: TextStyle(fontSize: 12, color: textSubColor),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => urlService.openEmail(
                    feedbackEmail,
                    subject: 'Listix Feedback',
                  ),
                ),
                if (showRateApp) ...[
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    key: const Key('settings_rate_app'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.star_rate_rounded,
                        color: Color(0xFFFFB800),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      tr.rateApp,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textTitleColor,
                      ),
                    ),
                    subtitle: Text(
                      tr.rateAppSubtitle,
                      style: TextStyle(fontSize: 12, color: textSubColor),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => urlService.openUrl(storeUrl),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SettingsSectionTitle(title: tr.aboutApp),
          const SizedBox(height: 10),
          _SettingsInfoCard(
            icon: Icons.cloud_off_rounded,
            title: '100% Offline-First',
            content: tr.offlineFirstStatement,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: textTitleColor,
            subColor: textSubColor,
          ),
          const SizedBox(height: 12),
          _SettingsInfoCard(
            icon: Icons.security_rounded,
            title: tr.privacyPolicy,
            content: tr.privacyStatement,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: textTitleColor,
            subColor: textSubColor,
          ),
          const SizedBox(height: 12),
          _SettingsInfoCard(
            icon: Icons.article_outlined,
            title: tr.termsOfService,
            content: tr.termsStatement,
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: textTitleColor,
            subColor: textSubColor,
          ),
          const SizedBox(height: 28),

          Center(
            child: Text(
              tr.copyrightFooter(DateTime.now().year),
              style: TextStyle(
                fontSize: 12,
                color: textSubColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color cardBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;

  const _SettingsInfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.cardBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 13, height: 1.5, color: subColor),
            ),
          ],
        ),
      ),
    );
  }
}
