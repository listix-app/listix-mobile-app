import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/backup_data.dart';
import '../../domain/entities/backup_result.dart';
import '../../domain/failures/backup_failure.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_local_data_source.dart';
import '../datasources/native_file_service.dart';

class BackupRepositoryImpl implements BackupRepository {
  final BackupLocalDataSource _localDataSource;
  final NativeFileService _nativeFileService;

  BackupRepositoryImpl({
    required BackupLocalDataSource localDataSource,
    required NativeFileService nativeFileService,
  }) : _localDataSource = localDataSource,
       _nativeFileService = nativeFileService;

  @override
  Future<BackupData> createBackupData() async {
    final lists = await _localDataSource.fetchAllLists();
    return BackupData(
      version: BackupData.currentSchemaVersion,
      exportedAt: DateTime.now(),
      appVersion: '1.0.0',
      lists: lists,
    );
  }

  @override
  Future<String> exportBackupJson() async {
    final backup = await createBackupData();
    return backup.toPrettyJson();
  }

  @override
  Future<String> exportBackupCsv() async {
    final backup = await createBackupData();
    return backup.toCsv();
  }

  @override
  Future<String> exportPlainTextSummary() async {
    final backup = await createBackupData();
    return backup.toPlainTextSummary();
  }

  @override
  Future<BackupData> parseBackupJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic> && decoded is! Map) {
        throw const BackupFailure('Backup JSON must be an object');
      }
      return BackupData.fromJson(Map<String, dynamic>.from(decoded as Map));
    } on BackupFailure {
      rethrow;
    } catch (e) {
      throw BackupFailure('Failed to parse backup JSON: $e');
    }
  }

  @override
  Future<BackupImportResult> restoreBackup(
    BackupData backup, {
    bool replaceExisting = false,
  }) async {
    return await _localDataSource.restoreLists(
      backup.lists,
      replaceExisting: replaceExisting,
    );
  }

  @override
  Future<BackupExportResult> saveBackupToFile({
    required String fileName,
    required String content,
    String? mimeType,
  }) async {
    final res = await _nativeFileService.saveFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType ?? 'application/json',
    );

    if (res != null) {
      return BackupExportResult(
        success: true,
        fileName: res['name'] as String?,
        filePath: res['uri'] as String?,
      );
    }

    return const BackupExportResult(
      success: false,
      message: 'Save operation canceled or unsupported',
    );
  }

  @override
  Future<Map<String, dynamic>?> pickBackupFile() async {
    return await _nativeFileService.pickAndReadFile();
  }

  @override
  Future<void> shareBackup({
    required String fileName,
    required String content,
    String? mimeType,
    String? subject,
  }) async {
    await _nativeFileService.shareFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
      subject: subject,
    );
  }
}

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final local = ref.watch(backupLocalDataSourceProvider);
  final native = ref.watch(nativeFileServiceProvider);
  return BackupRepositoryImpl(
    localDataSource: local,
    nativeFileService: native,
  );
});
