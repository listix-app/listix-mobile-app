import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/lists/data/repositories/sqlite_lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/sync/data/mock_backend_sync_service.dart';
import 'package:listix/src/features/sync/domain/sync_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
  });

  group('SqliteListsRepository & Database Integration Tests', () {
    late SqliteListsRepository repository;
    late MockBackendSyncService syncService;

    setUp(() async {
      AppDatabase.overrideDbPath = inMemoryDatabasePath;
      final db = await AppDatabase.instance.database;
      await db.delete('todo_items');
      await db.delete('collaborators');
      await db.delete('shopping_lists');

      repository = SqliteListsRepository();
      syncService = MockBackendSyncService();
    });

    test('Initial database has 0 lists when cleared', () async {
      final lists = await repository.getLists();
      expect(lists, isEmpty);
    });

    test('createList, getListById, updateListName, and deleteList', () async {
      final created = await repository.createList('Supermercado');
      expect(created.name, 'Supermercado');
      expect(created.items, isEmpty);
      expect(created.isSynced, isFalse);

      final fetched = await repository.getListById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Supermercado');

      final updated = await repository.updateListName(
        created.id,
        'Supermercado Semanal',
      );
      expect(updated.name, 'Supermercado Semanal');
      expect(
        () => repository.updateListName('non-existent-id', 'Nuevo nombre'),
        throwsException,
      );

      await repository.deleteList(created.id);
      final afterDelete = await repository.getListById(created.id);
      expect(afterDelete, isNull);
    });

    test('toggleListStar toggles isStarred in SQLite', () async {
      final list = await repository.createList('Lista Estrellada');
      expect(list.isStarred, isFalse);

      await repository.toggleListStar(list.id);
      var fetched = await repository.getListById(list.id);
      expect(fetched!.isStarred, isTrue);

      await repository.toggleListStar(list.id);
      fetched = await repository.getListById(list.id);
      expect(fetched!.isStarred, isFalse);
    });

    test('reorderLists updates positions in SQLite', () async {
      final list1 = await repository.createList('Lista 1');
      final list2 = await repository.createList('Lista 2');

      await repository.reorderLists([list2.id, list1.id]);
      final lists = await repository.getLists();
      expect(lists.first.id, list2.id);
      expect(lists.last.id, list1.id);
    });

    test('restoreList inserts restored list back into SQLite', () async {
      final list = await repository.createList('Lista Para Restaurar');
      await repository.addItem(list.id, 'Manzanas');
      await repository.addCollaborator(list.id, 'collab@test.com');
      final fullList = await repository.getListById(list.id);
      expect(fullList!.items.length, 1);
      expect(fullList.collaborators.length, 1);

      await repository.deleteList(list.id);
      expect(await repository.getListById(list.id), isNull);

      await repository.restoreList(fullList);
      final restored = await repository.getListById(list.id);
      expect(restored, isNotNull);
      expect(restored!.name, 'Lista Para Restaurar');
      expect(restored.items.length, 1);
      expect(restored.collaborators.length, 1);
    });

    test('addItem, toggleItemCompletion, and deleteItem', () async {
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

    test('reorderItems updates positions in SQLite', () async {
      final list = await repository.createList('Lista de orden items');
      final item1 = await repository.addItem(list.id, 'Item A');
      final item2 = await repository.addItem(list.id, 'Item B');

      await repository.reorderItems(list.id, [item2.id, item1.id]);
      final fetchedList = await repository.getListById(list.id);
      expect(fetchedList!.items.first.id, item2.id);
      expect(fetchedList.items.last.id, item1.id);
    });

    test('restoreItem inserts restored item back into SQLite', () async {
      final list = await repository.createList('Lista Restaurar Item');
      final item = await repository.addItem(list.id, 'Item a restaurar');
      await repository.deleteItem(list.id, item.id);

      var fetched = await repository.getListById(list.id);
      expect(fetched!.items.isEmpty, isTrue);

      await repository.restoreItem(item);
      fetched = await repository.getListById(list.id);
      expect(fetched!.items.length, 1);
      expect(fetched.items.first.title, 'Item a restaurar');
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

    test('syncList marks list and all its items as synced', () async {
      final list = await repository.createList('Lista para sincronizar');
      await repository.addItem(list.id, 'Item 1');
      await repository.addItem(list.id, 'Item 2');

      final beforeSync = await repository.getListById(list.id);
      expect(beforeSync!.isSynced, isFalse);
      expect(beforeSync.items.every((i) => !i.isSynced), isTrue);

      await repository.syncList(list.id);

      final afterSync = await repository.getListById(list.id);
      expect(afterSync!.isSynced, isTrue);
      expect(afterSync.items.every((i) => i.isSynced), isTrue);
    });

    test(
      'ListsController adds items in real-time immediately to state',
      () async {
        await repository.createList('Lista inicial');

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(listsControllerProvider.future);

        final lists = container.read(listsControllerProvider).value!;
        final targetList = lists.first;
        final initialItemCount = targetList.items.length;

        await container
            .read(listsControllerProvider.notifier)
            .addItem(targetList.id, 'Pan fresco de centeno');

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
      final list = await repository.createList('Lista por sincronizar');
      await repository.addItem(list.id, 'Item offline');

      final unSyncedList = await repository.getListById(list.id);
      expect(unSyncedList!.isSynced, isFalse);

      final success = await syncService.synchronize();
      expect(success, isTrue);
      expect(syncService.currentStatus, SyncStatus.synced);

      final syncedList = await repository.getListById(list.id);
      expect(syncedList!.isSynced, isTrue);
      expect(syncedList.items.first.isSynced, isTrue);
    });

    test(
      'MockBackendSyncService handles empty sync and offline mode',
      () async {
        final secondSync = await syncService.synchronize();
        expect(secondSync, isTrue);
        expect(syncService.currentStatus, SyncStatus.synced);

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

    test(
      'AppDatabase migration from version 1 to 2 executes _onUpgrade',
      () async {
        await AppDatabase.instance.close();
        const migrationDbPath = 'test_migration_v1_v2.db';
        final v1Db = await databaseFactory.openDatabase(
          migrationDbPath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
              CREATE TABLE shopping_lists (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                is_synced INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              );
            ''');
              await db.execute('''
              CREATE TABLE todo_items (
                id TEXT PRIMARY KEY NOT NULL,
                list_id TEXT NOT NULL,
                title TEXT NOT NULL,
                is_completed INTEGER NOT NULL DEFAULT 0,
                is_synced INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              );
            ''');
            },
          ),
        );
        await v1Db.close();

        AppDatabase.overrideDbPath = migrationDbPath;
        final upgradedDb = await AppDatabase.instance.database;
        final columnsLists = await upgradedDb.rawQuery(
          'PRAGMA table_info(shopping_lists);',
        );
        expect(columnsLists.any((c) => c['name'] == 'is_starred'), isTrue);
        expect(columnsLists.any((c) => c['name'] == 'position'), isTrue);

        final columnsItems = await upgradedDb.rawQuery(
          'PRAGMA table_info(todo_items);',
        );
        expect(columnsItems.any((c) => c['name'] == 'position'), isTrue);

        await AppDatabase.instance.close();
        await databaseFactory.deleteDatabase(migrationDbPath);
        AppDatabase.overrideDbPath = inMemoryDatabasePath;
        await AppDatabase.instance.database;
      },
    );
  });
}
