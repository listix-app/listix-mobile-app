import '../../domain/entities/backup_data.dart';
import '../../domain/entities/backup_result.dart';

enum BackupStatus { initial, loading, success, error }

class BackupState {
  final BackupStatus status;
  final String? message;
  final int totalLists;
  final int totalItems;
  final BackupData? pendingImportBackup;
  final BackupExportResult? lastExportResult;
  final BackupImportResult? lastImportResult;

  const BackupState({
    this.status = BackupStatus.initial,
    this.message,
    this.totalLists = 0,
    this.totalItems = 0,
    this.pendingImportBackup,
    this.lastExportResult,
    this.lastImportResult,
  });

  BackupState copyWith({
    BackupStatus? status,
    String? message,
    bool clearMessage = false,
    int? totalLists,
    int? totalItems,
    BackupData? pendingImportBackup,
    bool clearPendingImport = false,
    BackupExportResult? lastExportResult,
    BackupImportResult? lastImportResult,
  }) {
    return BackupState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      totalLists: totalLists ?? this.totalLists,
      totalItems: totalItems ?? this.totalItems,
      pendingImportBackup: clearPendingImport
          ? null
          : (pendingImportBackup ?? this.pendingImportBackup),
      lastExportResult: lastExportResult ?? this.lastExportResult,
      lastImportResult: lastImportResult ?? this.lastImportResult,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          message == other.message &&
          totalLists == other.totalLists &&
          totalItems == other.totalItems &&
          pendingImportBackup == other.pendingImportBackup &&
          lastExportResult == other.lastExportResult &&
          lastImportResult == other.lastImportResult;

  @override
  int get hashCode => Object.hash(
    status,
    message,
    totalLists,
    totalItems,
    pendingImportBackup,
    lastExportResult,
    lastImportResult,
  );
}
