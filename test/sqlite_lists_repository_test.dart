import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/lists/data/repositories/sqlite_lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/sync/data/mock_backend_sync_service.dart';
import 'package:listix/src/features/sync/domain/sync_status.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
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
      await db.delete('items');
      await db.delete('collaborators');
      await db.delete('lists');

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

        await repository.updateCollaboratorRole(
          list.id,
          addedCollab.id,
          CollaboratorRole.admin,
        );
        var updated = await repository.getListById(list.id);
        expect(updated!.collaborators.first.role, CollaboratorRole.admin);
        expect(updated.collaborators.first.isAdmin, isTrue);

        await repository.applyRemoteCollaboratorRole(
          list.id,
          addedCollab.id,
          CollaboratorRole.member,
        );
        updated = await repository.getListById(list.id);
        expect(updated!.collaborators.first.role, CollaboratorRole.member);

        // Test fallback on invalid role in database
        final db = await AppDatabase.instance.database;
        await db.execute(
          "INSERT INTO collaborators (id, list_id, name, email, is_owner, role) VALUES ('collab_unknown', '${list.id}', 'Unknown', 'unknown@test.com', 0, 'invalid_role');",
        );
        final withUnknown = await repository.getListById(list.id);
        final unknownCollab = withUnknown!.collaborators.firstWhere(
          (c) => c.id == 'collab_unknown',
        );
        expect(unknownCollab.role, CollaboratorRole.member);

        await repository.removeCollaborator(list.id, addedCollab.id);
        await repository.removeCollaborator(list.id, 'collab_unknown');
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
      expect(afterSync.isShared, isTrue);
      expect(afterSync.items.every((i) => i.isSynced), isTrue);
    });

    test('setListShared updates is_shared column in SQLite', () async {
      final list = await repository.createList('Lista Local Exclusiva');
      expect(list.isShared, isFalse);

      var fetched = await repository.getListById(list.id);
      expect(fetched!.isShared, isFalse);

      await repository.setListShared(list.id, true);
      fetched = await repository.getListById(list.id);
      expect(fetched!.isShared, isTrue);

      await repository.setListShared(list.id, false);
      fetched = await repository.getListById(list.id);
      expect(fetched!.isShared, isFalse);
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

    test(
      'joinSharedList, remote items, and remote collaborators in SQLite',
      () async {
        // 1. Join shared list when it does not exist yet (with owner)
        final joined = await repository.joinSharedList(
          'remote_list_1',
          'Lista Remota',
          ownerName: null,
          ownerEmail: 'admin@test.com',
        );
        expect(joined.id, 'remote_list_1');
        expect(joined.name, 'Lista Remota');
        expect(joined.isShared, isTrue);
        expect(joined.collaborators.length, 1);
        expect(joined.collaborators.first.isOwner, isTrue);
        expect(joined.collaborators.first.name, 'admin');

        // 2. Joining same list returns existing
        final rejoined = await repository.joinSharedList(
          'remote_list_1',
          'Nombre Diferente',
        );
        expect(rejoined.name, 'Lista Remota');

        // 3. Joining another with empty name and no owner
        final defaultList = await repository.joinSharedList(
          'remote_list_empty',
          '   ',
        );
        expect(defaultList.name, 'Lista compartida');
        expect(defaultList.collaborators, isEmpty);

        // 4. Apply remote item (insert)
        final remoteItem = TodoItem(
          id: 'r_item_1',
          listId: 'remote_list_1',
          title: 'Manzanas remotas',
          createdAt: DateTime.now(),
          position: 0,
        );
        await repository.applyRemoteItem(remoteItem);
        var fetched = await repository.getListById('remote_list_1');
        expect(fetched!.items.length, 1);
        expect(fetched.items.first.title, 'Manzanas remotas');

        // 5. Apply remote item toggle
        await repository.applyRemoteItemToggle(
          'remote_list_1',
          'r_item_1',
          true,
        );
        fetched = await repository.getListById('remote_list_1');
        expect(fetched!.items.first.isCompleted, isTrue);

        // 6. Apply remote item update
        await repository.applyRemoteItem(
          remoteItem.copyWith(title: 'Manzanas rojas'),
        );
        fetched = await repository.getListById('remote_list_1');
        expect(fetched!.items.first.title, 'Manzanas rojas');

        // 7. Apply remote item delete
        await repository.applyRemoteItemDelete('remote_list_1', 'r_item_1');
        fetched = await repository.getListById('remote_list_1');
        expect(fetched!.items, isEmpty);

        // 8. Apply remote collaborator
        const newCollab = Collaborator(
          id: 'collab_remote',
          name: 'Pedro',
          email: 'pedro@test.com',
        );
        await repository.applyRemoteCollaborator('remote_list_1', newCollab);
        fetched = await repository.getListById('remote_list_1');
        expect(
          fetched!.collaborators.any((c) => c.id == 'collab_remote'),
          isTrue,
        );

        // 9. Apply remote collaborator remove
        await repository.applyRemoteCollaboratorRemove(
          'remote_list_1',
          'collab_remote',
        );
        fetched = await repository.getListById('remote_list_1');
        expect(
          fetched!.collaborators.any((c) => c.id == 'collab_remote'),
          isFalse,
        );
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
        await databaseFactory.deleteDatabase(migrationDbPath);
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
          'PRAGMA table_info(lists);',
        );
        expect(columnsLists.any((c) => c['name'] == 'is_starred'), isTrue);
        expect(columnsLists.any((c) => c['name'] == 'position'), isTrue);

        final columnsItems = await upgradedDb.rawQuery(
          'PRAGMA table_info(items);',
        );
        expect(columnsItems.any((c) => c['name'] == 'position'), isTrue);

        await AppDatabase.instance.close();
        await databaseFactory.deleteDatabase(migrationDbPath);
        AppDatabase.overrideDbPath = inMemoryDatabasePath;
        await AppDatabase.instance.database;
      },
    );

    test(
      'AppDatabase migration from version 4 to 5 adds role column to collaborators',
      () async {
        await AppDatabase.instance.close();
        const migrationDbPath = 'test_migration_v4_v5.db';
        await databaseFactory.deleteDatabase(migrationDbPath);
        final v4Db = await databaseFactory.openDatabase(
          migrationDbPath,
          options: OpenDatabaseOptions(
            version: 4,
            onCreate: (db, version) async {
              await db.execute('''
              CREATE TABLE shopping_lists (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                is_synced INTEGER NOT NULL DEFAULT 0,
                is_starred INTEGER NOT NULL DEFAULT 0,
                is_shared INTEGER NOT NULL DEFAULT 0,
                position INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              );
            ''');
              await db.execute('''
              CREATE TABLE collaborators (
                id TEXT PRIMARY KEY NOT NULL,
                list_id TEXT NOT NULL,
                name TEXT NOT NULL,
                email TEXT NOT NULL,
                is_owner INTEGER NOT NULL DEFAULT 0
              );
            ''');
            },
          ),
        );
        await v4Db.close();

        AppDatabase.overrideDbPath = migrationDbPath;
        final upgradedDb = await AppDatabase.instance.database;
        final columnsCollabs = await upgradedDb.rawQuery(
          'PRAGMA table_info(collaborators);',
        );
        expect(columnsCollabs.any((c) => c['name'] == 'role'), isTrue);

        await AppDatabase.instance.close();
        await databaseFactory.deleteDatabase(migrationDbPath);
        AppDatabase.overrideDbPath = inMemoryDatabasePath;
        await AppDatabase.instance.database;
      },
    );

    test(
      'AppDatabase migration from version 5 to 6 renames tables to lists and items',
      () async {
        await AppDatabase.instance.close();
        const migrationDbPath = 'test_migration_v5_v6.db';
        final v5Db = await databaseFactory.openDatabase(
          migrationDbPath,
          options: OpenDatabaseOptions(
            version: 5,
            onCreate: (db, version) async {
              await db.execute('''
              CREATE TABLE shopping_lists (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                is_synced INTEGER NOT NULL DEFAULT 0,
                is_starred INTEGER NOT NULL DEFAULT 0,
                is_shared INTEGER NOT NULL DEFAULT 0,
                position INTEGER NOT NULL DEFAULT 0,
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
        await v5Db.close();

        AppDatabase.overrideDbPath = migrationDbPath;
        final upgradedDb = await AppDatabase.instance.database;
        final tables = await upgradedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table';",
        );
        final tableNames = tables.map((t) => t['name'] as String).toSet();
        expect(tableNames.contains('lists'), isTrue);
        expect(tableNames.contains('items'), isTrue);
        expect(tableNames.contains('shopping_lists'), isFalse);
        expect(tableNames.contains('todo_items'), isFalse);

        await AppDatabase.instance.close();
        await databaseFactory.deleteDatabase(migrationDbPath);
        AppDatabase.overrideDbPath = inMemoryDatabasePath;
        await AppDatabase.instance.database;
      },
    );
  });
}
