import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/listix_logo.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final localeNotifier = ref.read(localeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.aboutApp),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Hero Logo and App Identity
          Center(
            child: Column(
              children: [
                const ListixLogo(size: 68),
                const SizedBox(height: 14),
                const Text(
                  'Listix',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    tr.appTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Language Selector Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                        return AppColors.primaryLight;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primaryDark;
                      }
                      return AppColors.textSecondary;
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Offline-First Principle
          _InfoCard(
            icon: Icons.offline_bolt_outlined,
            title: tr.offlineFirstTitle,
            content: tr.offlineFirstStatement,
          ),

          const SizedBox(height: 16),

          // Privacy Policy
          _InfoCard(
            icon: Icons.shield_outlined,
            title: tr.privacyPolicy,
            content: tr.privacyStatement,
          ),

          const SizedBox(height: 16),

          // Terms of Service
          _InfoCard(
            icon: Icons.description_outlined,
            title: tr.termsOfService,
            content: tr.termsStatement,
          ),

          const SizedBox(height: 32),

          // Open Source / Copyright Footer
          Center(
            child: Text(
              tr.copyrightFooter(DateTime.now().year),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
