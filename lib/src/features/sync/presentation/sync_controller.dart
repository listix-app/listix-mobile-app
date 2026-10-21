import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth_session_service.dart';
import '../data/api_sync_service.dart';
import '../data/mock_backend_sync_service.dart';
import '../domain/sync_status.dart';

final mockBackendSyncServiceProvider = Provider<MockBackendSyncService>((ref) {
  final service = MockBackendSyncService();
  ref.onDispose(service.dispose);
  return service;
});

class SyncController extends Notifier<SyncStatus> {
  StreamSubscription<SyncStatus>? _subscription;
  Timer? _syncTimer;

  @override
  SyncStatus build() {
    final mockService = ref.watch(mockBackendSyncServiceProvider);
    final authSession = ref.watch(authSessionServiceProvider);

    if (authSession.isReady) {
      final realSync = ref.watch(apiSyncServiceProvider);
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          realSync.syncPendingOperations();
        }
      });
      realSync.syncPendingOperations();
      _subscription?.cancel();
      _subscription = realSync.statusStream.listen((status) {
        state = status;
      });
      ref.onDispose(() {
        _subscription?.cancel();
        _syncTimer?.cancel();
      });
      return realSync.currentStatus;
    }

    _subscription?.cancel();
    _subscription = mockService.statusStream.listen((status) {
      state = status;
    });
    ref.onDispose(() {
      _subscription?.cancel();
      _syncTimer?.cancel();
    });
    return mockService.currentStatus;
  }

  bool get isOffline {
    final authSession = ref.read(authSessionServiceProvider);
    if (authSession.isReady) {
      return ref.read(apiSyncServiceProvider).isSimulatedOffline;
    }
    return ref.read(mockBackendSyncServiceProvider).isSimulatedOffline;
  }

  void toggleOfflineMode() {
    final authSession = ref.read(authSessionServiceProvider);
    if (authSession.isReady) {
      final currentOffline = ref
          .read(apiSyncServiceProvider)
          .isSimulatedOffline;
      ref.read(apiSyncServiceProvider).setOfflineSimulation(!currentOffline);
    } else {
      ref.read(mockBackendSyncServiceProvider).toggleSimulatedOffline();
    }
  }

  Future<bool> syncNow() async {
    final authSession = ref.read(authSessionServiceProvider);
    if (authSession.isReady) {
      await ref.read(apiSyncServiceProvider).syncPendingOperations();
      return true;
    }
    return await ref.read(mockBackendSyncServiceProvider).synchronize();
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
