class BackupFailure implements Exception {
  final String message;

  const BackupFailure(this.message);

  @override
  String toString() => 'BackupFailure: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
