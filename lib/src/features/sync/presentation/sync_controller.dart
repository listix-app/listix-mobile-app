import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../lists/presentation/controllers/lists_controller.dart';
import '../data/mock_backend_sync_service.dart';
import '../data/supabase_sync_service.dart';
import '../domain/sync_status.dart';

final mockBackendSyncServiceProvider = Provider<MockBackendSyncService>((ref) {
  final service = MockBackendSyncService();
  ref.onDispose(service.dispose);
  return service;
});

final supabaseSyncServiceProvider = Provider<SupabaseSyncService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final listsRepo = ref.watch(listsRepositoryProvider);
  final service = SupabaseSyncService(
    supabaseService: supabaseService,
    listsRepository: listsRepo,
    onRemoteChangeApplied: () {
      ref.read(listsControllerProvider.notifier).manualSync();
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

class SyncController extends Notifier<SyncStatus> {
  StreamSubscription<SyncStatus>? _subscription;
  Timer? _syncTimer;

  @override
  SyncStatus build() {
    final mockService = ref.watch(mockBackendSyncServiceProvider);
    final supabaseService = ref.watch(supabaseServiceProvider);

    if (supabaseService.isReady) {
      final realSync = ref.watch(supabaseSyncServiceProvider);
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
    final supabaseService = ref.read(supabaseServiceProvider);
    if (supabaseService.isReady) {
      return state == SyncStatus.offline;
    }
    return ref.read(mockBackendSyncServiceProvider).isSimulatedOffline;
  }

  void toggleOfflineMode() {
    final supabaseService = ref.read(supabaseServiceProvider);
    if (supabaseService.isReady) {
      final currentOffline = state == SyncStatus.offline;
      ref
          .read(supabaseSyncServiceProvider)
          .setOfflineSimulation(!currentOffline);
    } else {
      ref.read(mockBackendSyncServiceProvider).toggleSimulatedOffline();
    }
  }

  Future<bool> syncNow() async {
    final supabaseService = ref.read(supabaseServiceProvider);
    if (supabaseService.isReady) {
      await ref.read(supabaseSyncServiceProvider).syncPendingOperations();
      return true;
    }
    return await ref.read(mockBackendSyncServiceProvider).synchronize();
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
