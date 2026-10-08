class BackupExportResult {
  final bool success;
  final String? fileName;
  final String? filePath;
  final String? message;

  const BackupExportResult({
    required this.success,
    this.fileName,
    this.filePath,
    this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupExportResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          fileName == other.fileName &&
          filePath == other.filePath &&
          message == other.message;

  @override
  int get hashCode => Object.hash(success, fileName, filePath, message);
}

class BackupImportResult {
  final bool success;
  final int listsRestored;
  final int itemsRestored;
  final String? message;

  const BackupImportResult({
    required this.success,
    required this.listsRestored,
    required this.itemsRestored,
    this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupImportResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          listsRestored == other.listsRestored &&
          itemsRestored == other.itemsRestored &&
          message == other.message;

  @override
  int get hashCode =>
      Object.hash(success, listsRestored, itemsRestored, message);
}
