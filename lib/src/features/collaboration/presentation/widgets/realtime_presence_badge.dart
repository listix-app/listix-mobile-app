import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../controllers/collaboration_controller.dart';

class RealtimePresenceBadge extends ConsumerWidget {
  final VoidCallback? onTap;

  const RealtimePresenceBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collaborationControllerProvider);
    final tr = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color dotColor;
    final Color badgeBg;
    final String label;

    switch (state.status) {
      case CollaborationStatus.connected:
        dotColor = AppColors.syncDone;
        badgeBg = isDark
            ? AppColors.syncDone.withValues(alpha: 0.15)
            : AppColors.syncDoneSubtle;
        label = state.onlineCount > 1
            ? '${tr.realtimeLive} (${state.onlineCount})'
            : tr.realtimeLive;
        break;
      case CollaborationStatus.connecting:
        dotColor = AppColors.syncPending;
        badgeBg = isDark
            ? AppColors.syncPending.withValues(alpha: 0.15)
            : AppColors.syncPendingSubtle;
        label = tr.realtimeConnecting;
        break;
      case CollaborationStatus.error:
        dotColor = AppColors.delete;
        badgeBg = isDark
            ? AppColors.delete.withValues(alpha: 0.15)
            : AppColors.deleteBackground;
        label = tr.realtimeDisconnected;
        break;
      case CollaborationStatus.disconnected:
        dotColor = AppColors.offline;
        badgeBg = isDark
            ? AppColors.offline.withValues(alpha: 0.15)
            : AppColors.offlineSubtle;
        label = tr.realtimeDisconnected;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dotColor.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: state.status == CollaborationStatus.connected
                    ? [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dotColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
