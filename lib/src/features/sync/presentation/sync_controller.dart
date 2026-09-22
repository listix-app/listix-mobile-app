import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_backend_sync_service.dart';
import '../domain/sync_status.dart';

final mockBackendSyncServiceProvider = Provider<MockBackendSyncService>((ref) {
  final service = MockBackendSyncService();
  ref.onDispose(service.dispose);
  return service;
});

class SyncController extends Notifier<SyncStatus> {
  StreamSubscription<SyncStatus>? _subscription;

  @override
  SyncStatus build() {
    final service = ref.watch(mockBackendSyncServiceProvider);
    _subscription?.cancel();
    _subscription = service.statusStream.listen((status) {
      state = status;
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return service.currentStatus;
  }

  bool get isOffline =>
      ref.read(mockBackendSyncServiceProvider).isSimulatedOffline;

  void toggleOfflineMode() {
    ref.read(mockBackendSyncServiceProvider).toggleSimulatedOffline();
  }

  Future<bool> syncNow() async {
    return await ref.read(mockBackendSyncServiceProvider).synchronize();
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
