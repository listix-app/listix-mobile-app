import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/features/sync/data/mock_backend_sync_service.dart';
import 'package:listix/src/features/sync/domain/sync_status.dart';
import 'package:listix/src/features/sync/presentation/sync_controller.dart';
import 'package:listix/src/features/sync/presentation/widgets/sync_status_badge.dart';

class TestableSyncService extends MockBackendSyncService {
  bool simulateOffline = false;
  SyncStatus simulatedStatus = SyncStatus.synced;
  int syncCalls = 0;

  @override
  bool get isSimulatedOffline => simulateOffline;

  @override
  SyncStatus get currentStatus => simulatedStatus;

  @override
  void toggleSimulatedOffline() {
    simulateOffline = !simulateOffline;
    simulatedStatus = simulateOffline ? SyncStatus.offline : SyncStatus.synced;
  }

  @override
  Future<bool> synchronize() async {
    syncCalls++;
    return true;
  }
}

void main() {
  group('SyncController & SyncStatusBadge Tests', () {
    test(
      'SyncController reflects service status and toggles offline mode',
      () async {
        final service = TestableSyncService();
        final container = ProviderContainer(
          overrides: [
            mockBackendSyncServiceProvider.overrideWithValue(service),
          ],
        );
        addTearDown(container.dispose);

        final status = container.read(syncControllerProvider);
        expect(status, SyncStatus.synced);
        expect(
          container.read(syncControllerProvider.notifier).isOffline,
          isFalse,
        );

        container.read(syncControllerProvider.notifier).toggleOfflineMode();
        expect(service.simulateOffline, isTrue);

        final didSync = await container
            .read(syncControllerProvider.notifier)
            .syncNow();
        expect(didSync, isTrue);
        expect(service.syncCalls, 1);
      },
    );

    testWidgets(
      'SyncStatusBadge renders synced, opens dialog and actions work',
      (tester) async {
        final service = TestableSyncService()
          ..simulatedStatus = SyncStatus.synced;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mockBackendSyncServiceProvider.overrideWithValue(service),
            ],
            child: const MaterialApp(
              home: Scaffold(body: Center(child: SyncStatusBadge())),
            ),
          ),
        );

        expect(find.text('Sincronizado'), findsOneWidget);

        await tester.tap(find.byType(SyncStatusBadge));
        await tester.pumpAndSettle();

        expect(find.text('Estado de Sincronización'), findsOneWidget);

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(service.simulateOffline, isTrue);

        await tester.tap(find.byType(SyncStatusBadge));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
        expect(find.text('Estado de Sincronización'), findsNothing);

        await tester.tap(find.byType(SyncStatusBadge));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sincronizar ahora'));
        await tester.pumpAndSettle();
        expect(service.syncCalls, 1);
      },
    );

    testWidgets(
      'SyncStatusBadge renders offline, syncing, and pendingChanges states',
      (tester) async {
        final states = [
          (SyncStatus.offline, 'Offline'),
          (SyncStatus.syncing, 'Sincronizando...'),
          (SyncStatus.pendingChanges, 'Pendiente'),
        ];

        for (final (status, label) in states) {
          final service = TestableSyncService()..simulatedStatus = status;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                mockBackendSyncServiceProvider.overrideWithValue(service),
              ],
              child: const MaterialApp(
                home: Scaffold(body: Center(child: SyncStatusBadge())),
              ),
            ),
          );

          expect(find.text(label), findsOneWidget);
        }
      },
    );
  });
}
