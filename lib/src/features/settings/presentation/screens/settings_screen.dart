import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/listix_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final localeNotifier = ref.read(localeControllerProvider.notifier);
    final currentThemeMode = ref.watch(themeModeControllerProvider);
    final themeNotifier = ref.read(themeModeControllerProvider.notifier);
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
                  tr.versionLabel('1.0.0', '1'),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 13, height: 1.45, color: subColor),
            ),
          ],
        ),
      ),
    );
  }
}
