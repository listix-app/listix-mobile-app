import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/sync_status.dart';
import '../sync_controller.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);
    final syncController = ref.read(syncControllerProvider.notifier);
    final tr = ref.watch(stringsProvider);

    final (bg, fg, icon, label) = switch (status) {
      SyncStatus.syncing => (
        AppColors.primarySubtle,
        AppColors.primary,
        Icons.sync_rounded,
        tr.statusSyncing,
      ),
      SyncStatus.offline => (
        AppColors.offlineSubtle,
        AppColors.offline,
        Icons.cloud_off_rounded,
        tr.statusOffline,
      ),
      SyncStatus.pendingChanges => (
        AppColors.syncPendingSubtle,
        AppColors.syncPending,
        Icons.sync_problem_rounded,
        tr.statusPending,
      ),
      SyncStatus.synced => (
        AppColors.syncDoneSubtle,
        AppColors.syncDone,
        Icons.cloud_done_rounded,
        tr.statusSynced,
      ),
    };

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr.syncStatusTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.syncStatusDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(tr.simulateOffline),
                  subtitle: Text(tr.simulateOfflineSubtitle),
                  value: syncController.isOffline,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    syncController.toggleOfflineMode();
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr.close),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await syncController.syncNow();
                },
                icon: const Icon(Icons.sync, size: 16),
                label: Text(tr.syncNow),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == SyncStatus.syncing)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            else
              Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
