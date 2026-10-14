import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/listix_logo.dart';
import '../controllers/app_lock_controller.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tr = ref.read(stringsProvider);
        ref.read(appLockControllerProvider.notifier).unlock(tr.appLockReason);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final lockState = ref.watch(appLockControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSubColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListixLogo(size: 72),
                  const SizedBox(height: 24),
                  Text(
                    tr.appLocked,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textTitleColor,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.appLockSubtitle,
                    style: TextStyle(fontSize: 14, color: textSubColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('unlock_app_button'),
                    onPressed: lockState.isAuthenticating
                        ? null
                        : () {
                            ref
                                .read(appLockControllerProvider.notifier)
                                .unlock(tr.appLockReason);
                          },
                    icon: lockState.isAuthenticating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.fingerprint_rounded, size: 22),
                    label: Text(
                      tr.unlockApp,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
