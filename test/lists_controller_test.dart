import 'package:listix/src/features/sync/domain/pending_operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/domain/repositories/lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/notifications/presentation/controllers/notifications_controller.dart';
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
  Future<ShoppingList> createList(String name, {int? color}) async {
    final list = ShoppingList(
      id: 'l_${internalLists.length + 1}',
      name: name,
      color: color,
      position: internalLists.length,
      createdAt: DateTime.now(),
    );
    internalLists.add(list);
    return list;
  }

  @override
  Future<ShoppingList> updateListName(
    String id,
    String newName, {
    int? color,
  }) async {
    if (newName.contains('FAIL')) {
      throw Exception('Simulated update error');
    }
    final index = internalLists.indexWhere((l) => l.id == id);
    if (index == -1) {
      throw Exception('Not found');
    }
    final updated = internalLists[index].copyWith(name: newName, color: color);
    internalLists[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteList(String id) async {
    if (id.contains('FAIL')) {
      throw Exception('Simulated delete error');
    }
    internalLists.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> toggleListStar(String listId) async {
    if (listId.contains('FAIL')) {
      throw Exception('Simulated star error');
    }
    final index = internalLists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final current = internalLists[index];
      internalLists[index] = current.copyWith(isStarred: !current.isStarred);
    }
  }

  @override
  Future<void> reorderLists(List<String> orderedListIds) async {
    if (orderedListIds.any((id) => id.contains('FAIL'))) {
      throw Exception('Simulated reorder error');
    }
    final reordered = <ShoppingList>[];
    for (var i = 0; i < orderedListIds.length; i++) {
      final list = internalLists.firstWhere((l) => l.id == orderedListIds[i]);
      reordered.add(list.copyWith(position: i));
    }
    internalLists = reordered;
  }

  @override
  Future<void> restoreList(ShoppingList list) async {
    if (list.id.contains('FAIL')) {
      throw Exception('Simulated restore error');
    }
    internalLists.removeWhere((l) => l.id == list.id);
    internalLists.add(list);
  }

  @override
  Future<TodoItem> addItem(String listId, String title, {String? id}) async {
    if (title.contains('FAIL')) {
      throw Exception('Simulated item error');
    }
    final item = TodoItem(
      id: id ?? 'item_1',
      listId: listId,
      title: title,
      createdAt: DateTime.now(),
    );
    final index = internalLists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      internalLists[index] = internalLists[index].copyWith(
        items: [...internalLists[index].items, item],
      );
    }
    return item;
  }

  @override
  Future<TodoItem> toggleItemCompletion(String listId, String itemId) async {
    if (itemId.contains('FAIL')) {
      throw Exception('Simulated toggle error');
    }
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
    if (itemId.contains('FAIL')) {
      throw Exception('Simulated delete item error');
    }
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
  Future<void> reorderItems(String listId, List<String> orderedItemIds) async {
    if (orderedItemIds.any((id) => id.contains('FAIL'))) {
      throw Exception('Simulated item reorder error');
    }
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final currentItems = internalLists[listIndex].items;
      final reordered = <TodoItem>[];
      for (var i = 0; i < orderedItemIds.length; i++) {
        final item = currentItems.firstWhere(
          (it) => it.id == orderedItemIds[i],
        );
        reordered.add(item.copyWith(position: i));
      }
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        items: reordered,
      );
    }
  }

  @override
  Future<void> restoreItem(TodoItem item) async {
    if (item.id.contains('FAIL')) {
      throw Exception('Simulated item restore error');
    }
    final listIndex = internalLists.indexWhere((l) => l.id == item.listId);
    if (listIndex != -1) {
      final items = [...internalLists[listIndex].items, item];
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        items: items,
      );
    }
  }

  @override
  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  }) async {
    if (email.contains('FAIL')) {
      throw Exception('Simulated add collaborator failure');
    }
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final collab = Collaborator(
        id: 'c_$email',
        name: email,
        email: email,
        role: role,
      );
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        collaborators: [...internalLists[listIndex].collaborators, collab],
      );
    }
  }

  @override
  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final collabs = internalLists[listIndex].collaborators.map((c) {
        if (c.id == collaboratorId) return c.copyWith(role: role);
        return c;
      }).toList();
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        collaborators: collabs,
      );
    }
  }

  @override
  Future<void> applyRemoteCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    await updateCollaboratorRole(listId, collaboratorId, role);
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

  @override
  Future<void> syncList(String listId) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        isSynced: true,
        isShared: true,
      );
    }
  }

  @override
  Future<void> setListShared(
    String listId,
    bool isShared, {
    bool? hasInvite,
  }) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        isShared: isShared,
        hasInvite: isShared
            ? (hasInvite ?? internalLists[listIndex].hasInvite)
            : false,
      );
    }
  }

  @override
  Future<void> markListInviteCreated(String listId) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        isShared: true,
        hasInvite: true,
      );
    }
  }

  @override
  Future<ShoppingList> joinSharedList(
    String listId,
    String name, {
    String? ownerName,
    String? ownerEmail,
  }) async {
    final list = ShoppingList(
      id: listId,
      name: name,
      position: internalLists.length,
      createdAt: DateTime.now(),
      collaborators: [
        Collaborator(
          id: 'owner_$listId',
          name: ownerName ?? 'Owner',
          email: ownerEmail ?? 'owner@listix.local',
          isOwner: true,
        ),
      ],
    );
    internalLists.add(list);
    return list;
  }

  @override
  Future<void> applyRemoteItem(TodoItem item) async {
    final listIndex = internalLists.indexWhere((l) => l.id == item.listId);
    if (listIndex != -1) {
      final existingIdx = internalLists[listIndex].items.indexWhere(
        (i) => i.id == item.id,
      );
      final List<TodoItem> items;
      if (existingIdx >= 0) {
        items = List<TodoItem>.from(internalLists[listIndex].items);
        items[existingIdx] = item;
      } else {
        items = [...internalLists[listIndex].items, item];
      }
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        items: items,
      );
    }
  }

  @override
  Future<void> applyRemoteItemToggle(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final items = internalLists[listIndex].items.map((i) {
        if (i.id == itemId) return i.copyWith(isCompleted: isCompleted);
        return i;
      }).toList();
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        items: items,
      );
    }
  }

  @override
  Future<void> applyRemoteItemDelete(String listId, String itemId) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final items = internalLists[listIndex].items
          .where((i) => i.id != itemId)
          .toList();
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        items: items,
      );
    }
  }

  @override
  Future<void> applyRemoteCollaborator(
    String listId,
    Collaborator collaborator,
  ) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final existingIdx = internalLists[listIndex].collaborators.indexWhere(
        (c) => c.id == collaborator.id,
      );
      final List<Collaborator> collabs;
      if (existingIdx >= 0) {
        collabs = List<Collaborator>.from(
          internalLists[listIndex].collaborators,
        );
        collabs[existingIdx] = collaborator;
      } else {
        collabs = [...internalLists[listIndex].collaborators, collaborator];
      }
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        collaborators: collabs,
      );
    }
  }

  @override
  Future<void> applyRemoteCollaboratorRemove(
    String listId,
    String collaboratorId,
  ) async {
    final listIndex = internalLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final collabs = internalLists[listIndex].collaborators
          .where((c) => c.id != collaboratorId)
          .toList();
      internalLists[listIndex] = internalLists[listIndex].copyWith(
        collaborators: collabs,
      );
    }
  }

  @override
  Future<void> saveRemoteList(ShoppingList list) async {
    final idx = internalLists.indexWhere((l) => l.id == list.id);
    if (idx != -1) {
      internalLists[idx] = list;
    } else {
      internalLists.add(list);
    }
  }

  @override
  Future<List<PendingOperation>> getPendingOperations({String? listId}) async =>
      [];

  @override
  Future<void> removePendingOperation(String id) async {}

  @override
  Future<void> clearPendingOperationsForList(String listId) async {}

  @override
  Future<void> archiveList(String listId) async {
    if (listId.contains('FAIL')) throw Exception('Simulated archive error');
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(isArchived: true);
    }
  }

  @override
  Future<void> unarchiveList(String listId) async {
    if (listId.contains('FAIL')) throw Exception('Simulated unarchive error');
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(isArchived: false);
    }
  }

  @override
  Future<TodoItem> updateItemTitle(
    String listId,
    String itemId,
    String newTitle,
  ) async {
    if (newTitle.contains('FAIL')) {
      throw Exception('Simulated update item error');
    }
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      final itemIdx = internalLists[idx].items.indexWhere(
        (i) => i.id == itemId,
      );
      if (itemIdx != -1) {
        final updated = internalLists[idx].items[itemIdx].copyWith(
          title: newTitle,
        );
        final newItems = List<TodoItem>.from(internalLists[idx].items);
        newItems[itemIdx] = updated;
        internalLists[idx] = internalLists[idx].copyWith(items: newItems);
        return updated;
      }
    }
    throw UnimplementedError();
  }

  @override
  Future<void> applyRemoteItemUpdate(
    String listId,
    String itemId,
    String newTitle,
  ) async {
    await updateItemTitle(listId, itemId, newTitle);
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

class _FakeNotificationsController extends NotificationsController {
  final bool _initialEnabled;
  int showCallCount = 0;
  bool shouldThrow = false;

  _FakeNotificationsController(this._initialEnabled);

  @override
  NotificationsState build() => NotificationsState(isEnabled: _initialEnabled);

  @override
  Future<void> showItemNotification({
    required String listName,
    required String itemTitle,
  }) async {
    if (shouldThrow) {
      throw Exception('Simulated notification error');
    }
    showCallCount++;
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
            position: 0,
            items: [
              TodoItem(
                id: 'item_1',
                listId: 'list_1',
                title: 'Leche',
                position: 0,
                createdAt: now,
              ),
              TodoItem(
                id: 'item_2',
                listId: 'list_1',
                title: 'Huevos',
                position: 1,
                createdAt: now,
              ),
            ],
            createdAt: now,
          ),
          ShoppingList(
            id: 'list_2',
            name: 'Ferretería',
            position: 1,
            items: const [],
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
        expect(lists.length, 2);
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
      expect(currentLists.length, 3);
    });

    test(
      'updateListName updates optimistically and rolls back on failure',
      () async {
        await container.read(listsControllerProvider.future);

        await container
            .read(listsControllerProvider.notifier)
            .updateListName('list_1', 'Nombre actualizado');
        expect(
          container.read(shoppingListProvider('list_1'))!.name,
          'Nombre actualizado',
        );

        await expectLater(
          container
              .read(listsControllerProvider.notifier)
              .updateListName('list_1', 'FAIL Nombre'),
          throwsA(isA<Exception>()),
        );
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

        await container
            .read(listsControllerProvider.notifier)
            .deleteList('list_1');
        expect(container.read(shoppingListProvider('list_1')), isNull);
      },
    );

    test(
      'deleteListWithUndo removes and returns list for restoration',
      () async {
        await container.read(listsControllerProvider.future);

        final nonExistent = await container
            .read(listsControllerProvider.notifier)
            .deleteListWithUndo('non_existent');
        expect(nonExistent, isNull);

        final deleted = await container
            .read(listsControllerProvider.notifier)
            .deleteListWithUndo('list_1');
        expect(deleted, isNotNull);
        expect(deleted!.name, 'Compras iniciales');
        expect(container.read(shoppingListProvider('list_1')), isNull);

        final starredDeleted = deleted.copyWith(isStarred: true);
        await container
            .read(listsControllerProvider.notifier)
            .restoreList(starredDeleted);
        expect(container.read(shoppingListProvider('list_1')), isNotNull);
      },
    );

    test('restoreList rolls back on repository failure', () async {
      await container.read(listsControllerProvider.future);

      final failingList = ShoppingList(
        id: 'list_FAIL_restore',
        name: 'Failing Restore',
        createdAt: DateTime.now(),
      );

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .restoreList(failingList),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteListWithUndo rolls back on failure', () async {
      await container.read(listsControllerProvider.future);

      fakeRepo.internalLists.add(
        ShoppingList(
          id: 'list_FAIL_undo',
          name: 'Fails on delete',
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(listsControllerProvider);
      await container.read(listsControllerProvider.future);

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .deleteListWithUndo('list_FAIL_undo'),
        throwsA(isA<Exception>()),
      );
      expect(container.read(shoppingListProvider('list_FAIL_undo')), isNotNull);
    });

    test('toggleStar pins starred list and rolls back on failure', () async {
      await container.read(listsControllerProvider.future);

      await container
          .read(listsControllerProvider.notifier)
          .toggleStar('list_2');
      var lists = container.read(listsControllerProvider).value!;
      expect(lists.first.id, 'list_2');
      expect(lists.first.isStarred, isTrue);

      await container
          .read(listsControllerProvider.notifier)
          .toggleStar('list_2');
      lists = container.read(listsControllerProvider).value!;
      expect(lists.any((l) => l.id == 'list_2' && !l.isStarred), isTrue);

      fakeRepo.internalLists.add(
        ShoppingList(
          id: 'list_FAIL_star',
          name: 'Fails star',
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(listsControllerProvider);
      await container.read(listsControllerProvider.future);

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .toggleStar('list_FAIL_star'),
        throwsA(isA<Exception>()),
      );
    });

    test('reorderLists changes positions and rolls back on failure', () async {
      await container.read(listsControllerProvider.future);

      await container.read(listsControllerProvider.notifier).reorderLists(0, 2);
      var lists = container.read(listsControllerProvider).value!;
      expect(lists.first.id, 'list_2');

      await container.read(listsControllerProvider.notifier).reorderLists(1, 0);
      lists = container.read(listsControllerProvider).value!;
      expect(lists.first.id, 'list_1');

      fakeRepo.internalLists.add(
        ShoppingList(
          id: 'list_FAIL_reorder',
          name: 'Fails reorder',
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(listsControllerProvider);
      await container.read(listsControllerProvider.future);

      await expectLater(
        container.read(listsControllerProvider.notifier).reorderLists(0, 1),
        throwsA(isA<Exception>()),
      );
    });

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

      await container
          .read(listsControllerProvider.notifier)
          .deleteItem('list_1', 'item_1');
      final list = container.read(shoppingListProvider('list_1'))!;
      expect(list.items.any((i) => i.id == 'item_1'), isFalse);
    });

    test('deleteItemWithUndo deletes and restores item', () async {
      await container.read(listsControllerProvider.future);

      final nonExistent = await container
          .read(listsControllerProvider.notifier)
          .deleteItemWithUndo('list_1', 'non_existent');
      expect(nonExistent, isNull);

      final deleted = await container
          .read(listsControllerProvider.notifier)
          .deleteItemWithUndo('list_1', 'item_2');
      expect(deleted, isNotNull);
      expect(deleted!.title, 'Huevos');

      var list = container.read(shoppingListProvider('list_1'))!;
      expect(list.items.any((i) => i.id == 'item_2'), isFalse);

      await container
          .read(listsControllerProvider.notifier)
          .restoreItem(deleted);
      list = container.read(shoppingListProvider('list_1'))!;
      expect(list.items.any((i) => i.id == 'item_2'), isTrue);
    });

    test('deleteItemWithUndo and restoreItem roll back on failure', () async {
      await container.read(listsControllerProvider.future);

      fakeRepo.internalLists.first = fakeRepo.internalLists.first.copyWith(
        items: [
          TodoItem(
            id: 'item_FAIL_undo',
            listId: 'list_1',
            title: 'Fail undo',
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
            .deleteItemWithUndo('list_1', 'item_FAIL_undo'),
        throwsA(isA<Exception>()),
      );

      final failingRestore = TodoItem(
        id: 'item_FAIL_res',
        listId: 'list_1',
        title: 'Fail restore',
        createdAt: DateTime.now(),
      );

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .restoreItem(failingRestore),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'reorderItems reorders items in list and rolls back on failure',
      () async {
        await container.read(listsControllerProvider.future);

        await container
            .read(listsControllerProvider.notifier)
            .reorderItems('list_1', 0, 2);
        var list = container.read(shoppingListProvider('list_1'))!;
        expect(list.items.first.id, 'item_2');

        await container
            .read(listsControllerProvider.notifier)
            .reorderItems('list_1', 5, 0);
        await container
            .read(listsControllerProvider.notifier)
            .reorderItems('list_1', 0, -1);
        list = container.read(shoppingListProvider('list_1'))!;
        expect(list.items.first.id, 'item_2');

        fakeRepo.internalLists.first = fakeRepo.internalLists.first.copyWith(
          items: [
            TodoItem(
              id: 'item_FAIL_reorder',
              listId: 'list_1',
              title: 'Fail reorder',
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
              .reorderItems('list_1', 0, 1),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'addCollaborator and removeCollaborator update controller state',
      () async {
        await container.read(listsControllerProvider.future);

        await container
            .read(listsControllerProvider.notifier)
            .addCollaborator(
              'list_1',
              'maria@example.invalid',
              role: CollaboratorRole.admin,
            );
        var list = container.read(shoppingListProvider('list_1'))!;
        expect(list.collaborators.length, 1);
        expect(list.collaborators.first.role, CollaboratorRole.admin);

        await container
            .read(listsControllerProvider.notifier)
            .addCollaborator('list_1', 'maria@example.invalid');
        expect(
          container.read(shoppingListProvider('list_1'))!.collaborators.length,
          1,
        );

        await expectLater(
          container
              .read(listsControllerProvider.notifier)
              .addCollaborator('list_1', 'FAIL@example.com'),
          throwsA(isA<Exception>()),
        );

        await container
            .read(listsControllerProvider.notifier)
            .syncListOnShare('list_2');
        await container
            .read(listsControllerProvider.notifier)
            .inviteCollaborator(
              'list_2',
              'invitee@example.com',
              role: CollaboratorRole.member,
            );
        final list2Collabs = container
            .read(shoppingListProvider('list_2'))!
            .collaborators;
        expect(
          list2Collabs.any((c) => c.email == 'invitee@example.com'),
          isTrue,
        );

        await container
            .read(listsControllerProvider.notifier)
            .updateCollaboratorRole(
              'list_1',
              'c_maria@example.invalid',
              CollaboratorRole.member,
            );
        list = container.read(shoppingListProvider('list_1'))!;
        expect(list.collaborators.first.role, CollaboratorRole.member);

        await container
            .read(listsControllerProvider.notifier)
            .applyRemoteCollaboratorRole(
              'list_1',
              'c_maria@example.invalid',
              CollaboratorRole.admin,
            );
        list = container.read(shoppingListProvider('list_1'))!;
        expect(list.collaborators.first.role, CollaboratorRole.admin);

        await container
            .read(listsControllerProvider.notifier)
            .removeCollaborator('list_1', 'c_maria@example.invalid');
        list = container.read(shoppingListProvider('list_1'))!;
        expect(list.collaborators.isEmpty, isTrue);
      },
    );

    test('manualSync refreshes state from repository', () async {
      await container.read(listsControllerProvider.future);
      await container.read(listsControllerProvider.notifier).manualSync();
      final lists = container.read(listsControllerProvider).value!;
      expect(lists.length, 2);
      expect(lists.first.name, 'Compras iniciales');
    });

    test(
      'syncListOnShare calls repo.syncList and updates list state',
      () async {
        await container.read(listsControllerProvider.future);
        await container
            .read(listsControllerProvider.notifier)
            .syncListOnShare('list_1');
        final list = container.read(shoppingListProvider('list_1'))!;
        expect(list.isSynced, isTrue);
        expect(list.isShared, isTrue);
      },
    );

    test(
      'setListShared toggles list sharing status and only syncs when invite is created',
      () async {
        await container.read(listsControllerProvider.future);

        // Initially list_2 is not shared
        var list2 = container.read(shoppingListProvider('list_2'))!;
        expect(list2.isShared, isFalse);

        // Turn sharing ON without invite -> should be shared, but not sync yet
        await container
            .read(listsControllerProvider.notifier)
            .setListShared('list_2', true);
        list2 = container.read(shoppingListProvider('list_2'))!;
        expect(list2.isShared, isTrue);
        expect(list2.hasInvite, isFalse);
        expect(list2.canSyncAndShare, isFalse);
        expect(list2.isSynced, isFalse);

        // Generate/share invite -> now can sync and share
        await container
            .read(listsControllerProvider.notifier)
            .syncListOnShare('list_2');
        list2 = container.read(shoppingListProvider('list_2'))!;
        expect(list2.isShared, isTrue);
        expect(list2.hasInvite, isTrue);
        expect(list2.canSyncAndShare, isTrue);
        expect(list2.isSynced, isTrue);

        // Turn sharing on when hasInvite is already true (canSyncAndShare true) to trigger syncList
        await fakeRepo.markListInviteCreated('list_2');
        await container
            .read(listsControllerProvider.notifier)
            .setListShared('list_2', true);
        list2 = container.read(shoppingListProvider('list_2'))!;
        expect(list2.canSyncAndShare, isTrue);

        // Turn sharing OFF -> should reset sharing and invite
        await container
            .read(listsControllerProvider.notifier)
            .setListShared('list_2', false);
        list2 = container.read(shoppingListProvider('list_2'))!;
        expect(list2.isShared, isFalse);
        expect(list2.hasInvite, isFalse);
        expect(list2.canSyncAndShare, isFalse);
      },
    );

    test('archiveList updates state and handles repository failure', () async {
      await container.read(listsControllerProvider.future);

      fakeRepo.internalLists.add(
        ShoppingList(
          id: 'list_FAIL_archive',
          name: 'Failing archive',
          createdAt: DateTime.now(),
        ),
      );
      container.invalidate(listsControllerProvider);
      await container.read(listsControllerProvider.future);

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .archiveList('list_FAIL_archive'),
        throwsA(isA<Exception>()),
      );

      await container
          .read(listsControllerProvider.notifier)
          .archiveList('list_1');
      expect(
        container.read(shoppingListProvider('list_1'))!.isArchived,
        isTrue,
      );
    });

    test(
      'unarchiveList updates state and handles repository failure',
      () async {
        await container.read(listsControllerProvider.future);

        fakeRepo.internalLists.add(
          ShoppingList(
            id: 'list_FAIL_unarchive',
            name: 'Failing unarchive',
            isArchived: true,
            createdAt: DateTime.now(),
          ),
        );
        container.invalidate(listsControllerProvider);
        await container.read(listsControllerProvider.future);

        await expectLater(
          container
              .read(listsControllerProvider.notifier)
              .unarchiveList('list_FAIL_unarchive'),
          throwsA(isA<Exception>()),
        );

        await container
            .read(listsControllerProvider.notifier)
            .unarchiveList('list_1');
        expect(
          container.read(shoppingListProvider('list_1'))!.isArchived,
          isFalse,
        );
      },
    );

    test('updateItem updates title in state and broadcasts event', () async {
      await container.read(listsControllerProvider.future);

      await expectLater(
        container
            .read(listsControllerProvider.notifier)
            .updateItem('list_1', 'item_1', 'FAIL_title'),
        throwsA(isA<Exception>()),
      );

      await container
          .read(listsControllerProvider.notifier)
          .updateItem('list_1', 'item_1', 'Leche Entera');
      final item = container
          .read(shoppingListProvider('list_1'))!
          .items
          .firstWhere((i) => i.id == 'item_1');
      expect(item.title, 'Leche Entera');
    });

    test('applyRemoteItemUpdate updates local item state', () async {
      await container.read(listsControllerProvider.future);

      await container
          .read(listsControllerProvider.notifier)
          .applyRemoteItemUpdate('list_1', 'item_1', 'Leche Descremada');
      final item = container
          .read(shoppingListProvider('list_1'))!
          .items
          .firstWhere((i) => i.id == 'item_1');
      expect(item.title, 'Leche Descremada');
    });

    test(
      'addItem notification fires only when active, shared, and online',
      () async {
        final sharedList = ShoppingList(
          id: 'shared_list_notif',
          name: 'Compartida',
          isShared: true,
          hasInvite: true,
          createdAt: DateTime(2026, 9, 22),
        );
        final privateList = ShoppingList(
          id: 'private_list_notif',
          name: 'Privada',
          isShared: false,
          createdAt: DateTime(2026, 9, 22),
        );
        final customRepo = FakeFailingListsRepository(
          initial: [sharedList, privateList],
        );
        final customSync = FakeBackendSyncService();
        final fakeNotif = _FakeNotificationsController(true);

        final customContainer = ProviderContainer(
          overrides: [
            listsRepositoryProvider.overrideWithValue(customRepo),
            mockBackendSyncServiceProvider.overrideWithValue(customSync),
            notificationsControllerProvider.overrideWith(() => fakeNotif),
          ],
        );
        addTearDown(customContainer.dispose);
        await customContainer.read(listsControllerProvider.future);

        await customContainer
            .read(listsControllerProvider.notifier)
            .addItem('shared_list_notif', 'Pan');
        expect(fakeNotif.showCallCount, 1);

        await customContainer
            .read(listsControllerProvider.notifier)
            .addItem('private_list_notif', 'Vino');
        expect(fakeNotif.showCallCount, 1);

        customSync.toggleSimulatedOffline();
        await customContainer
            .read(listsControllerProvider.notifier)
            .addItem('shared_list_notif', 'Cerveza');
        expect(fakeNotif.showCallCount, 1);

        customSync.toggleSimulatedOffline();
        fakeNotif.shouldThrow = true;
        await customContainer
            .read(listsControllerProvider.notifier)
            .addItem('shared_list_notif', 'Queso');
        expect(fakeNotif.showCallCount, 1);
      },
    );

    test('addItem does not notify when notifications are inactive', () async {
      final sharedList = ShoppingList(
        id: 'shared_list_inactive',
        name: 'Compartida 2',
        isShared: true,
        hasInvite: true,
        createdAt: DateTime(2026, 9, 22),
      );
      final customRepo = FakeFailingListsRepository(initial: [sharedList]);
      final customSync = FakeBackendSyncService();
      final fakeNotif = _FakeNotificationsController(false);

      final customContainer = ProviderContainer(
        overrides: [
          listsRepositoryProvider.overrideWithValue(customRepo),
          mockBackendSyncServiceProvider.overrideWithValue(customSync),
          notificationsControllerProvider.overrideWith(() => fakeNotif),
        ],
      );
      addTearDown(customContainer.dispose);
      await customContainer.read(listsControllerProvider.future);

      await customContainer
          .read(listsControllerProvider.notifier)
          .addItem('shared_list_inactive', 'Manzana');
      expect(fakeNotif.showCallCount, 0);
    });
  });
}
