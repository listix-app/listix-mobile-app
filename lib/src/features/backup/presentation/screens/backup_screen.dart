import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_context.dart';
import '../controllers/backup_controller.dart';
import '../controllers/backup_state.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  Future<void> _showRestoreDialog(
    BuildContext context,
    WidgetRef ref,
    AppStrings tr,
    int listsCount,
    int itemsCount,
  ) async {
    final notifier = ref.read(backupControllerProvider.notifier);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(tr.restoreConfirmTitle),
          content: Text(tr.restoreConfirmMessage(listsCount, itemsCount)),
          actions: [
            TextButton(
              onPressed: () {
                notifier.clearPendingImport();
                Navigator.of(dialogContext).pop();
              },
              child: Text(tr.cancel),
            ),
            OutlinedButton(
              key: const Key('restore_dialog_merge_button'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final res = await notifier.confirmRestore(
                  replaceExisting: false,
                );
                if (context.mounted && res != null && res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr.restoreSuccess(res.listsRestored, res.itemsRestored),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: Text(tr.restoreMerge),
            ),
            ElevatedButton(
              key: const Key('restore_dialog_replace_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.delete,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final res = await notifier.confirmRestore(
                  replaceExisting: true,
                );
                if (context.mounted && res != null && res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr.restoreSuccess(res.listsRestored, res.itemsRestored),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: Text(tr.restoreReplace),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final backupAsync = ref.watch(backupControllerProvider);
    final notifier = ref.read(backupControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = context.cardSurface;
    final borderColor = context.borderColor;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSubColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final backupState = backupAsync.value ?? const BackupState();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.backupAndExport),
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
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.listsSummaryTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textTitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tr.totalListsCount(backupState.totalLists)} • ${tr.totalItemsCount(backupState.totalItems)}',
                          style: TextStyle(fontSize: 13, color: textSubColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: tr.exportDataCsv),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              key: const Key('export_data_csv_tile'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.syncDone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: AppColors.syncDone,
                  size: 22,
                ),
              ),
              title: Text(
                tr.exportDataCsv,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textTitleColor,
                ),
              ),
              subtitle: Text(
                tr.exportDataCsvDesc,
                style: TextStyle(fontSize: 12, color: textSubColor),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: () async {
                final res = await notifier.exportAndSaveCsvFile();
                if (context.mounted && res != null && res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr.csvExportSuccess),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: tr.backupDataJson),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              key: const Key('backup_data_json_tile'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.save_alt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                tr.backupDataJson,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textTitleColor,
                ),
              ),
              subtitle: Text(
                tr.backupDataJsonDesc,
                style: TextStyle(fontSize: 12, color: textSubColor),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: () async {
                final res = await notifier.exportAndSaveJsonFile();
                if (context.mounted && res != null && res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr.backupSuccess),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: tr.restoreJson),
          const SizedBox(height: 10),
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              key: const Key('restore_json_tile'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: AppColors.accentIndigo,
                  size: 22,
                ),
              ),
              title: Text(
                tr.restoreJson,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textTitleColor,
                ),
              ),
              subtitle: Text(
                tr.restoreJsonDesc,
                style: TextStyle(fontSize: 12, color: textSubColor),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: () async {
                final parsed = await notifier.pickBackupFile();
                if (context.mounted && parsed != null) {
                  await _showRestoreDialog(
                    context,
                    ref,
                    tr,
                    parsed.totalLists,
                    parsed.totalItems,
                  );
                } else if (context.mounted) {
                  final latestState =
                      ref.read(backupControllerProvider).value ??
                      const BackupState();
                  if (latestState.status == BackupStatus.error &&
                      latestState.message != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(latestState.message!),
                        backgroundColor: AppColors.delete,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.primary,
      ),
    );
  }
}
