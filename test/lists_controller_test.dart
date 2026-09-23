import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/domain/repositories/lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/sync/data/mock_backend_sync_service.dart';
import 'package:listix/src/features/sync/presentation/sync_controller.dart';

class FakeFailingListsRepository implements ListsRepository {
  List<ShoppingList> internalLists = [];

  FakeFailingListsRepository({List<ShoppingList>? initial})
    : internalLists = initial ?? [];

  @override
  Future<List<ShoppingList>> getLists() async => List.from(internalLists);

  @override
  Future<ShoppingList?> getListById(String id) async {
    return internalLists.where((l) => l.id == id).firstOrNull;
  }

  @override
  Future<ShoppingList> createList(String name) async {
    final list = ShoppingList(
      id: 'l_${internalLists.length + 1}',
      name: name,
      createdAt: DateTime.now(),
    );
    internalLists.add(list);
    return list;
  }

  @override
  Future<ShoppingList> updateListName(String id, String newName) async {
    if (newName.contains('FAIL')) throw Exception('Simulated update error');
    final index = internalLists.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Not found');
    final updated = internalLists[index].copyWith(name: newName);
    internalLists[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteList(String id) async {
    if (id.contains('FAIL')) throw Exception('Simulated delete error');
    internalLists.removeWhere((l) => l.id == id);
  }

  @override
  Future<TodoItem> addItem(String listId, String title, {String? id}) async {
    if (title.contains('FAIL')) throw Exception('Simulated item error');
    final item = TodoItem(
      id: id ?? 'item_1',
      listId: listId,
      title: title,
      createdAt: DateTime.now(),
    );
    final index = internalLists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      internalLists[index] = internalLists[index].copyWith(
        items: [item, ...internalLists[index].items],
      );
    }
    return item;
  }

  @override
  Future<TodoItem> toggleItemCompletion(String listId, String itemId) async {
    if (itemId.contains('FAIL')) throw Exception('Simulated toggle error');
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    final itemIndex = internalLists[listIndex].items.indexWhere(
      (i) => i.id == itemId,
    );
    final current = internalLists[listIndex].items[itemIndex];
    final updated = current.copyWith(isCompleted: !current.isCompleted);
    final newItems = List<TodoItem>.from(internalLists[listIndex].items);
    newItems[itemIndex] = updated;
    internalLists[listIndex] = internalLists[listIndex].copyWith(
      items: newItems,
    );
    return updated;
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {
    if (itemId.contains('FAIL')) throw Exception('Simulated delete item error');
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final newItems = internalLists[listIndex].items
          .where((i) => i.id != itemId)
          .toList();
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        items: newItems,
      );
    }
  }

  @override
  Future<void> addCollaborator(String listId, String email) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final collab = Collaborator(id: 'c_$email', name: email, email: email);
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        collaborators: [...internalLists[listIndex].collaborators, collab],
      );
    }
  }

  @override
  Future<void> removeCollaborator(String listId, String collaboratorId) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final newCollabs = internalLists[listIndex].collaborators
          .where((c) => c.id != collaboratorId)
          .toList();
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        collaborators: newCollabs,
      );
    }
  }
}

class FakeBackendSyncService extends MockBackendSyncService {
  int syncCallCount = 0;

  @override
  Future<bool> synchronize() async {
    syncCallCount++;
    return true;
  }
}

void main() {
  group('ListsController Unit Tests', () {
    late FakeFailingListsRepository fakeRepo;
    late FakeBackendSyncService fakeSync;
    late ProviderContainer container;

    setUp(() {
      final now = DateTime(2026, 9, 22);
      fakeRepo = FakeFailingListsRepository(
        initial: [
          ShoppingList(
            id: 'list_1',
            name: 'Compras iniciales',
            items: [
              TodoItem(
                id: 'item_1',
                listId: 'list_1',
                title: 'Leche',
                createdAt: now,
              ),
            ],
            createdAt: now,
          ),
        ],
      );
      fakeSync = FakeBackendSyncService();

      container = ProviderContainer(
        overrides: [
          listsRepositoryProvider.overrideWithValue(fakeRepo),
          mockBackendSyncServiceProvider.overrideWithValue(fakeSync),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'build loads initial lists and shoppingListProvider reads by ID',
      () async {
        final lists = await container.read(listsControllerProvider.future);
        expect(lists.length, 1);
        expect(lists.first.name, 'Compras iniciales');

        final singleList = container.read(shoppingListProvider('list_1'));
        expect(singleList, isNotNull);
        expect(singleList!.name, 'Compras iniciales');

        final unknownList = container.read(shoppingListProvider('unknown_id'));
        expect(unknownList, isNull);
      },
    );

    test('createList creates list and updates state', () async {
      await container.read(listsControllerProvider.future);
      final created = await container
          .read(listsControllerProvider.notifier)
          .createList('Nueva lista test');

      expect(created.name, 'Nueva lista test');
      final currentLists = container.read(listsControllerProvider).value!;
      expect(currentLists.length, 2);
    });

    test(
      'updateListName updates optimistically and rolls back on failure',
      () async {
        await container.read(listsControllerProvider.future);

        // Successful update
        await container
            .read(listsControllerProvider.notifier)
            .updateListName('list_1', 'Nombre actualizado');
        expect(
          container.read(shoppingListProvider('list_1'))!.name,
          'Nombre actualizado',
        );

        // Failed update
        await expectLater(
          container
              .read(listsControllerProvider.notifier)
              .updateListName('list_1', 'FAIL Nombre'),
          throwsA(isA<Exception>()),
        );
        // Rolled back
        expect(
          container.read(shoppingListProvider('list_1'))!.name,
          'Nombre actualizado',
        );
      },
    );

    test(
      'deleteList removes optimistically and rolls back on failure',
      () async {
        await container.read(listsControllerProvider.future);

        // Add a failing list to repo
        fakeRepo.internalLists.add(
          ShoppingList(
            id: 'list_FAIL',
            name: 'Lista falla',
            createdAt: DateTime.now(),
          ),
        );
        container.invalidate(listsControllerProvider);
        await container.read(listsControllerProvider.future);

        await expectLater(
          container
              .read(listsControllerProvider.notifier)
              .deleteList('list_FAIL'),
          throwsA(isA<Exception>()),
        );
        expect(container.read(shoppingListProvider('list_FAIL')), isNotNull);

        // Successful delete
        await container
            .read(listsControllerProvider.notifier)
            .deleteList('list_1');
        expect(container.read(shoppingListProvider('list_1')), isNull);
      },
    );

    test(
      'addItem adds item optimistically and rolls back on failure',
      () async {
        await container.read(listsControllerProvider.future);

        await container
            .read(listsControllerProvider.notifier)
            .addItem('list_1', 'Arroz integral');
        final list = container.read(shoppingListProvider('list_1'))!;
        expect(list.items.any((i) => i.title == 'Arroz integral'), isTrue);

        await expectLater(
          container
              .read(listsControllerProvider.notifier)
              .addItem('list_1', 'FAIL Item'),
          throwsA(isA<Exception>()),
        );
        final listAfterRollback = container.read(
          shoppingListProvider('list_1'),
        )!;
        expect(
          listAfterRollback.items.any((i) => i.title.contains('FAIL')),
          isFalse,
        );
      },
    );

    test('toggleItem toggles completion and rolls back on failure', () async {
      await container.read(listsControllerProvider.future);

      await container
          .read(listsControllerProvider.notifier)
          .toggleItem('list_1', 'item_1');
      var list = container.read(shoppingListProvider('list_1'))!;
      expect(list.items.first.isCompleted, isTrue);

      // Add failing item
      fakeRepo.internalLists.first = fakeRepo.internalLists.first.copyWith(
        items: [
          TodoItem(
            id: 'item_FAIL',
            listId: 'list_1',
            title: 'Failing',
            createdAt: DateTime.now(),
          ),
          ...fakeRepo.internalLists.first.items,
        ],
      );
      container.invalidate(listsControllerProvider);
      await container.read(listsControllerProvider.future);

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .toggleItem('list_1', 'item_FAIL'),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteItem deletes item and rolls back on failure', () async {
      await container.read(listsControllerProvider.future);

      // Add failing item
      fakeRepo.internalLists.first = fakeRepo.internalLists.first.copyWith(
        items: [
          TodoItem(
            id: 'item_FAIL_del',
            listId: 'list_1',
            title: 'Failing Delete',
            createdAt: DateTime.now(),
          ),
          ...fakeRepo.internalLists.first.items,
        ],
      );
      container.invalidate(listsControllerProvider);
      await container.read(listsControllerProvider.future);

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .deleteItem('list_1', 'item_FAIL_del'),
        throwsA(isA<Exception>()),
      );

      // Successful delete
      await container
          .read(listsControllerProvider.notifier)
          .deleteItem('list_1', 'item_1');
      final list = container.read(shoppingListProvider('list_1'))!;
      expect(list.items.any((i) => i.id == 'item_1'), isFalse);
    });

    test(
      'addCollaborator and removeCollaborator update controller state',
      () async {
        await container.read(listsControllerProvider.future);

        await container
            .read(listsControllerProvider.notifier)
            .addCollaborator('list_1', 'maria@listix.app');
        var list = container.read(shoppingListProvider('list_1'))!;
        expect(list.collaborators.length, 1);

        await container
            .read(listsControllerProvider.notifier)
            .removeCollaborator('list_1', 'c_maria@listix.app');
        list = container.read(shoppingListProvider('list_1'))!;
        expect(list.collaborators.isEmpty, isTrue);
      },
    );

    test('manualSync calls sync service and refreshes state', () async {
      await container.read(listsControllerProvider.future);
      await container.read(listsControllerProvider.notifier).manualSync();
      expect(fakeSync.syncCallCount, 1);
    });

    test('background sync debounce triggers after delay', () async {
      await container.read(listsControllerProvider.future);
      await container
          .read(listsControllerProvider.notifier)
          .createList('Debounced Sync List');

      expect(fakeSync.syncCallCount, 0);

      // Wait for debounce timer (1200ms)
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(fakeSync.syncCallCount, greaterThanOrEqualTo(1));
    });
  });
}
