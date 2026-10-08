import '../entities/backup_data.dart';
import '../entities/backup_result.dart';

abstract interface class BackupRepository {
  Future<BackupData> createBackupData();
  Future<String> exportBackupJson();
  Future<String> exportBackupCsv();
  Future<String> exportPlainTextSummary();
  Future<BackupData> parseBackupJson(String jsonString);
  Future<BackupImportResult> restoreBackup(
    BackupData backup, {
    bool replaceExisting = false,
  });
  Future<BackupExportResult> saveBackupToFile({
    required String fileName,
    required String content,
    String? mimeType,
  });
  Future<Map<String, dynamic>?> pickBackupFile();
  Future<void> shareBackup({
    required String fileName,
    required String content,
    String? mimeType,
    String? subject,
  });
}
