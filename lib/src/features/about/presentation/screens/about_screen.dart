import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/listix_logo.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

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
        title: Text(tr.aboutApp),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          Center(
            child: Column(
              children: [
                const ListixLogo(size: 72),
                const SizedBox(height: 12),
                Text(
                  'Listix',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: textTitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tr.versionLabel('1.0.0', '1'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSubColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ActionCard(
            key: const Key('buy_coffee_card'),
            icon: Icons.coffee_rounded,
            iconColor: const Color(0xFFFF813F),
            title: tr.buyMeACoffee,
            subtitle: tr.buyMeACoffeeSubtitle,
            onTap: () {
              urlService.openUrl(coffeeUrl);
            },
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: textTitleColor,
            subColor: textSubColor,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            key: const Key('send_feedback_card'),
            icon: Icons.feedback_outlined,
            iconColor: const Color(0xFF6366F1),
            title: tr.sendFeedback,
            subtitle: tr.sendFeedbackSubtitle,
            onTap: () {
              urlService.openEmail(feedbackEmail, subject: 'Listix Feedback');
            },
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: textTitleColor,
            subColor: textSubColor,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            key: const Key('rate_app_card'),
            icon: Icons.star_rate_rounded,
            iconColor: const Color(0xFFFFB800),
            title: tr.rateApp,
            subtitle: tr.rateAppSubtitle,
            onTap: () {
              urlService.openUrl(storeUrl);
            },
            cardBg: cardBg,
            borderColor: borderColor,
            titleColor: textTitleColor,
            subColor: textSubColor,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr.themeTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textTitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(tr.themeSystem),
                      icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(tr.themeLight),
                      icon: const Icon(Icons.light_mode_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(tr.themeDark),
                      icon: const Icon(Icons.dark_mode_rounded, size: 16),
                    ),
                  ],
                  selected: {currentThemeMode},
                  onSelectionChanged: (selected) {
                    themeNotifier.setThemeMode(selected.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr.languageTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textTitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<AppLanguage>(
                  segments: [
                    ButtonSegment(
                      value: AppLanguage.es,
                      label: Text(tr.spanish),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: AppLanguage.en,
                      label: Text(tr.english),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                    ),
                  ],
                  selected: {
                    locale.languageCode == 'en'
                        ? AppLanguage.en
                        : AppLanguage.es,
                  },
                  onSelectionChanged: (selected) {
                    localeNotifier.setLanguage(selected.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight;
                      }
                      return cardBg;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return isDark ? Colors.white : AppColors.primaryDark;
                      }
                      return textSubColor;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.offline_bolt_outlined,
            title: tr.offlineFirstTitle,
            content: tr.offlineFirstStatement,
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.shield_outlined,
            title: tr.privacyPolicy,
            content: tr.privacyStatement,
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.description_outlined,
            title: tr.termsOfService,
            content: tr.termsStatement,
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              tr.copyrightFooter(DateTime.now().year),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color cardBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.cardBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: subColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSubColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
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
                  fontWeight: FontWeight.w700,
                  color: textTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: textSubColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}
