import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/lists/data/repositories/sqlite_lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/sync/data/mock_backend_sync_service.dart';
import 'package:listix/src/features/sync/domain/sync_status.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
  });

  group('SqliteListsRepository & MockBackendSyncService', () {
    late SqliteListsRepository repository;
    late MockBackendSyncService syncService;

    setUp(() async {
      repository = SqliteListsRepository();
      syncService = MockBackendSyncService();
      // Ensure DB created and seeded
      await AppDatabase.instance.database;
    });

    test('getLists returns seeded lists from SQLite', () async {
      final lists = await repository.getLists();
      expect(lists.length, greaterThanOrEqualTo(3));
      expect(lists.any((l) => l.name == 'Supermercado semanal'), isTrue);
    });

    test('getListById returns null for unknown ID', () async {
      final notFound = await repository.getListById('unknown-999');
      expect(notFound, isNull);
    });

    test('createList creates list with is_synced = false', () async {
      final created = await repository.createList('Lista de prueba');
      expect(created.name, 'Lista de prueba');
      expect(created.isSynced, isFalse);

      final lists = await repository.getLists();
      expect(lists.any((l) => l.id == created.id), isTrue);
    });

    test('updateListName updates list and throws if not found', () async {
      final list = await repository.createList('Lista original');
      final updated = await repository.updateListName(
        list.id,
        'Lista renombrada',
      );
      expect(updated.name, 'Lista renombrada');

      expect(
        () => repository.updateListName('non-existent-id', 'Nuevo nombre'),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteList removes list from database', () async {
      final list = await repository.createList('Lista a eliminar');
      await repository.deleteList(list.id);
      final check = await repository.getListById(list.id);
      expect(check, isNull);
    });

    test('addItem and toggleItemCompletion mutate SQLite state', () async {
      final list = await repository.createList('Lista para items');
      final item = await repository.addItem(list.id, 'Manzanas rojas');

      expect(item.title, 'Manzanas rojas');
      expect(item.isCompleted, isFalse);
      expect(item.isSynced, isFalse);

      final toggled = await repository.toggleItemCompletion(list.id, item.id);
      expect(toggled.isCompleted, isTrue);

      final updatedList = await repository.getListById(list.id);
      expect(updatedList!.items.first.isCompleted, isTrue);

      await repository.deleteItem(list.id, item.id);
      final listAfterDelete = await repository.getListById(list.id);
      expect(listAfterDelete!.items.isEmpty, isTrue);
    });

    test(
      'addCollaborator and removeCollaborator update list collaborators',
      () async {
        final list = await repository.createList('Lista colaborativa');
        await repository.addCollaborator(list.id, 'carlos@ejemplo.com');

        final listWithCollab = await repository.getListById(list.id);
        expect(listWithCollab!.collaborators.length, 1);
        final addedCollab = listWithCollab.collaborators.first;
        expect(addedCollab.name, 'Carlos');
        expect(addedCollab.email, 'carlos@ejemplo.com');
        expect(addedCollab.isOwner, isFalse);

        await repository.removeCollaborator(list.id, addedCollab.id);
        final listWithoutCollab = await repository.getListById(list.id);
        expect(listWithoutCollab!.collaborators.isEmpty, isTrue);
      },
    );

    test(
      'ListsController adds items in real-time immediately to state',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Await initial build
        await container.read(listsControllerProvider.future);

        final lists = container.read(listsControllerProvider).value!;
        final targetList = lists.first;
        final initialItemCount = targetList.items.length;

        // Add item via controller
        await container
            .read(listsControllerProvider.notifier)
            .addItem(targetList.id, 'Pan fresco de centeno');

        // Verify that state contains the new item immediately
        final updatedLists = container.read(listsControllerProvider).value!;
        final updatedTargetList = updatedLists.firstWhere(
          (l) => l.id == targetList.id,
        );
        expect(updatedTargetList.items.length, initialItemCount + 1);
        expect(updatedTargetList.items.first.title, 'Pan fresco de centeno');
        expect(updatedTargetList.items.first.isCompleted, isFalse);
      },
    );

    test('MockBackendSyncService synchronizes un-synced items', () async {
      // Create a list with an un-synced item
      final list = await repository.createList('Lista por sincronizar');
      await repository.addItem(list.id, 'Item offline');

      // Verify pending items exist
      final unSyncedList = await repository.getListById(list.id);
      expect(unSyncedList!.isSynced, isFalse);

      // Run sync
      final success = await syncService.synchronize();
      expect(success, isTrue);
      expect(syncService.currentStatus, SyncStatus.synced);

      // Verify that after sync, isSynced is true in SQLite
      final syncedList = await repository.getListById(list.id);
      expect(syncedList!.isSynced, isTrue);
      expect(syncedList.items.first.isSynced, isTrue);
    });

    test(
      'MockBackendSyncService handles empty sync and offline mode',
      () async {
        // Empty sync: nothing left to sync
        final secondSync = await syncService.synchronize();
        expect(secondSync, isTrue);
        expect(syncService.currentStatus, SyncStatus.synced);

        // Offline mode
        syncService.toggleSimulatedOffline();
        expect(syncService.isSimulatedOffline, isTrue);
        expect(syncService.currentStatus, SyncStatus.offline);

        final failedSync = await syncService.synchronize();
        expect(failedSync, isFalse);

        syncService.toggleSimulatedOffline();
        expect(syncService.isSimulatedOffline, isFalse);
        expect(syncService.currentStatus, SyncStatus.synced);

        syncService.dispose();
      },
    );

    test('AppDatabase close and reopen', () async {
      await AppDatabase.instance.close();
      final reopenedDb = await AppDatabase.instance.database;
      expect(reopenedDb.isOpen, isTrue);
    });
  });
}
