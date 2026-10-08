import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lists/presentation/controllers/lists_controller.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/entities/backup_data.dart';
import '../../domain/entities/backup_result.dart';
import '../../domain/failures/backup_failure.dart';
import 'backup_state.dart';

class BackupController extends AsyncNotifier<BackupState> {
  @override
  Future<BackupState> build() async {
    final repo = ref.watch(backupRepositoryProvider);
    final backup = await repo.createBackupData();
    return BackupState(
      totalLists: backup.totalLists,
      totalItems: backup.totalItems,
    );
  }

  Future<void> refreshStats() async {
    final repo = ref.read(backupRepositoryProvider);
    final backup = await repo.createBackupData();
    state = AsyncData(
      (state.value ?? const BackupState()).copyWith(
        totalLists: backup.totalLists,
        totalItems: backup.totalItems,
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y$m${d}_$h$min';
  }

  Future<BackupExportResult?> exportAndSaveCsvFile() async {
    final previous = state.value ?? const BackupState();
    state = AsyncData(
      previous.copyWith(status: BackupStatus.loading, clearMessage: true),
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      final csvContent = await repo.exportBackupCsv();
      final now = DateTime.now();
      final fileName = 'listix_export_${_formatTimestamp(now)}.csv';

      final result = await repo.saveBackupToFile(
        fileName: fileName,
        content: csvContent,
        mimeType: 'text/csv',
      );

      state = AsyncData(
        previous.copyWith(
          status: result.success ? BackupStatus.success : BackupStatus.initial,
          lastExportResult: result,
          message: result.success ? result.fileName ?? fileName : null,
        ),
      );
      return result;
    } catch (e) {
      state = AsyncData(
        previous.copyWith(status: BackupStatus.error, message: e.toString()),
      );
      return null;
    }
  }

  Future<BackupExportResult?> exportAndSaveJsonFile() async {
    final previous = state.value ?? const BackupState();
    state = AsyncData(
      previous.copyWith(status: BackupStatus.loading, clearMessage: true),
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      final jsonContent = await repo.exportBackupJson();
      final now = DateTime.now();
      final fileName = 'listix_backup_${_formatTimestamp(now)}.json';

      final result = await repo.saveBackupToFile(
        fileName: fileName,
        content: jsonContent,
        mimeType: 'application/json',
      );

      state = AsyncData(
        previous.copyWith(
          status: result.success ? BackupStatus.success : BackupStatus.initial,
          lastExportResult: result,
          message: result.success ? result.fileName ?? fileName : null,
        ),
      );
      return result;
    } catch (e) {
      state = AsyncData(
        previous.copyWith(status: BackupStatus.error, message: e.toString()),
      );
      return null;
    }
  }

  Future<void> exportAndShareJsonFile({String? subject}) async {
    final previous = state.value ?? const BackupState();
    state = AsyncData(
      previous.copyWith(status: BackupStatus.loading, clearMessage: true),
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      final jsonContent = await repo.exportBackupJson();
      final now = DateTime.now();
      final fileName = 'listix_backup_${_formatTimestamp(now)}.json';

      await repo.shareBackup(
        fileName: fileName,
        content: jsonContent,
        mimeType: 'application/json',
        subject: subject ?? 'Listix Backup',
      );

      state = AsyncData(
        previous.copyWith(status: BackupStatus.success, message: fileName),
      );
    } catch (e) {
      state = AsyncData(
        previous.copyWith(status: BackupStatus.error, message: e.toString()),
      );
    }
  }

  Future<void> exportAndSharePlainText({String? subject}) async {
    final previous = state.value ?? const BackupState();
    state = AsyncData(
      previous.copyWith(status: BackupStatus.loading, clearMessage: true),
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      final textContent = await repo.exportPlainTextSummary();
      final now = DateTime.now();
      final fileName = 'listix_summary_${_formatTimestamp(now)}.txt';

      await repo.shareBackup(
        fileName: fileName,
        content: textContent,
        mimeType: 'text/plain',
        subject: subject ?? 'Listix Summary',
      );

      state = AsyncData(
        previous.copyWith(status: BackupStatus.success, message: fileName),
      );
    } catch (e) {
      state = AsyncData(
        previous.copyWith(status: BackupStatus.error, message: e.toString()),
      );
    }
  }

  Future<BackupData?> pickBackupFile() async {
    final previous = state.value ?? const BackupState();
    state = AsyncData(
      previous.copyWith(status: BackupStatus.loading, clearMessage: true),
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      final fileData = await repo.pickBackupFile();
      if (fileData == null) {
        state = AsyncData(previous.copyWith(status: BackupStatus.initial));
        return null;
      }

      final content = fileData['content'] as String? ?? '';
      final parsed = await repo.parseBackupJson(content);

      state = AsyncData(
        previous.copyWith(
          status: BackupStatus.initial,
          pendingImportBackup: parsed,
        ),
      );
      return parsed;
    } catch (e) {
      final msg = e is BackupFailure ? e.message : e.toString();
      state = AsyncData(
        previous.copyWith(status: BackupStatus.error, message: msg),
      );
      return null;
    }
  }

  Future<BackupImportResult?> confirmRestore({
    required bool replaceExisting,
  }) async {
    final previous = state.value ?? const BackupState();
    final backupToRestore = previous.pendingImportBackup;
    if (backupToRestore == null) {
      return null;
    }

    state = AsyncData(
      previous.copyWith(status: BackupStatus.loading, clearMessage: true),
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      final result = await repo.restoreBackup(
        backupToRestore,
        replaceExisting: replaceExisting,
      );

      ref.invalidate(listsControllerProvider);
      await refreshStats();

      state = AsyncData(
        (state.value ?? previous).copyWith(
          status: BackupStatus.success,
          clearPendingImport: true,
          lastImportResult: result,
        ),
      );
      return result;
    } catch (e) {
      state = AsyncData(
        previous.copyWith(status: BackupStatus.error, message: e.toString()),
      );
      return null;
    }
  }

  Future<BackupImportResult?> restoreFromJsonContent(
    String content, {
    required bool replaceExisting,
  }) async {
    final previous = state.value ?? const BackupState();
    state = AsyncData(
      previous.copyWith(status: BackupStatus.loading, clearMessage: true),
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      final parsed = await repo.parseBackupJson(content);
      final result = await repo.restoreBackup(
        parsed,
        replaceExisting: replaceExisting,
      );

      ref.invalidate(listsControllerProvider);
      await refreshStats();

      state = AsyncData(
        (state.value ?? previous).copyWith(
          status: BackupStatus.success,
          lastImportResult: result,
        ),
      );
      return result;
    } catch (e) {
      final msg = e is BackupFailure ? e.message : e.toString();
      state = AsyncData(
        previous.copyWith(status: BackupStatus.error, message: msg),
      );
      return null;
    }
  }

  void clearPendingImport() {
    final current = state.value ?? const BackupState();
    state = AsyncData(current.copyWith(clearPendingImport: true));
  }
}

final backupControllerProvider =
    AsyncNotifierProvider<BackupController, BackupState>(BackupController.new);
