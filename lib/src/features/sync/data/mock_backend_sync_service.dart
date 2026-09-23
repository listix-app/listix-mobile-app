import 'dart:async';

import '../../../core/storage/app_database.dart';
import '../domain/sync_status.dart';

class MockBackendSyncService {
  final AppDatabase _appDatabase;
  bool _isSimulatedOffline = false;
  SyncStatus _currentStatus = SyncStatus.synced;
  final _statusController = StreamController<SyncStatus>.broadcast();

  MockBackendSyncService({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;
  bool get isSimulatedOffline => _isSimulatedOffline;

  void toggleSimulatedOffline() {
    _isSimulatedOffline = !_isSimulatedOffline;
    _updateStatus(_isSimulatedOffline ? SyncStatus.offline : SyncStatus.synced);
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Performs simulated synchronization against a mock backend.
  /// Reads pending items from SQLite, simulates network latency,
  /// and updates records to `is_synced = 1`.
  Future<bool> synchronize() async {
    if (_isSimulatedOffline) {
      _updateStatus(SyncStatus.offline);
      return false;
    }

    final db = await _appDatabase.database;

    // Check if there are un-synced items or lists
    final unsyncedLists = await db.query(
      'shopping_lists',
      where: 'is_synced = 0',
    );
    final unsyncedItems = await db.query('todo_items', where: 'is_synced = 0');

    if (unsyncedLists.isEmpty && unsyncedItems.isEmpty) {
      _updateStatus(SyncStatus.synced);
      return true;
    }

    _updateStatus(SyncStatus.syncing);

    // Simulate backend network latency
    await Future.delayed(const Duration(milliseconds: 900));

    if (_isSimulatedOffline) {
      _updateStatus(SyncStatus.offline);
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Mark lists as synced in SQLite
    await db.update('shopping_lists', {
      'is_synced': 1,
      'updated_at': now,
    }, where: 'is_synced = 0');

    // Mark items as synced in SQLite
    await db.update('todo_items', {
      'is_synced': 1,
      'updated_at': now,
    }, where: 'is_synced = 0');

    _updateStatus(SyncStatus.synced);
    return true;
  }

  void dispose() {
    _statusController.close();
  }
}
