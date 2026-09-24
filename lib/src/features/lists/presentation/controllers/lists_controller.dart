import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/sqlite_lists_repository.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/todo_item.dart';
import '../../domain/repositories/lists_repository.dart';

final listsRepositoryProvider = Provider<ListsRepository>((ref) {
  return SqliteListsRepository();
});

class ListsController extends AsyncNotifier<List<ShoppingList>> {
  static const _uuid = Uuid();

  @override
  FutureOr<List<ShoppingList>> build() async {
    final repository = ref.read(listsRepositoryProvider);
    return repository.getLists();
  }

  Future<void> syncListOnShare(String listId) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.syncList(listId);
    state = AsyncData(await repository.getLists());
  }

  Future<ShoppingList> createList(String name) async {
    final repository = ref.read(listsRepositoryProvider);
    final created = await repository.createList(name);
    state = AsyncData(await repository.getLists());
    return created;
  }

  Future<void> updateListName(String id, String newName) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == id) {
          return l.copyWith(name: newName.trim(), isSynced: false);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.updateListName(id, newName);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> deleteList(String id) async {
    final currentLists = state.value;
    if (currentLists != null) {
      state = AsyncData(currentLists.where((l) => l.id != id).toList());
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.deleteList(id);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<ShoppingList?> deleteListWithUndo(String id) async {
    final currentLists = state.value;
    final targetList = currentLists?.where((l) => l.id == id).firstOrNull;
    if (targetList == null) return null;

    state = AsyncData(currentLists!.where((l) => l.id != id).toList());

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.deleteList(id);
      return targetList;
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> restoreList(ShoppingList list) async {
    final currentLists = state.value ?? [];
    final updatedLists = [...currentLists, list];
    updatedLists.sort((a, b) {
      if (a.isStarred != b.isStarred) {
        return a.isStarred ? -1 : 1;
      }
      return a.position.compareTo(b.position);
    });
    state = AsyncData(updatedLists);

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.restoreList(list);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> toggleStar(String id) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == id) {
          return l.copyWith(isStarred: !l.isStarred);
        }
        return l;
      }).toList();

      updatedLists.sort((a, b) {
        if (a.isStarred != b.isStarred) {
          return a.isStarred ? -1 : 1;
        }
        return a.position.compareTo(b.position);
      });
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.toggleListStar(id);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    final currentLists = state.value;
    if (currentLists == null || currentLists.isEmpty) return;

    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }

    final updatedLists = List<ShoppingList>.from(currentLists);
    final movedList = updatedLists.removeAt(oldIndex);
    updatedLists.insert(targetIndex, movedList);

    final reordered = <ShoppingList>[];
    for (var i = 0; i < updatedLists.length; i++) {
      reordered.add(updatedLists[i].copyWith(position: i));
    }
    state = AsyncData(reordered);

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.reorderLists(reordered.map((l) => l.id).toList());
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> addItem(String listId, String title) async {
    final itemId = _uuid.v4();
    final now = DateTime.now();

    final currentLists = state.value;
    final targetList = currentLists?.where((l) => l.id == listId).firstOrNull;
    final nextPosition = (targetList?.items.length ?? 0);

    final optimisticItem = TodoItem(
      id: itemId,
      listId: listId,
      title: title.trim(),
      isCompleted: false,
      isSynced: false,
      position: nextPosition,
      createdAt: now,
    );

    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          return l.copyWith(
            isSynced: false,
            items: [...l.items, optimisticItem],
          );
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.addItem(listId, title, id: itemId);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> toggleItem(String listId, String itemId) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedItems = l.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(
                isCompleted: !item.isCompleted,
                isSynced: false,
              );
            }
            return item;
          }).toList();
          return l.copyWith(isSynced: false, items: updatedItems);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.toggleItemCompletion(listId, itemId);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedItems = l.items.where((i) => i.id != itemId).toList();
          return l.copyWith(isSynced: false, items: updatedItems);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.deleteItem(listId, itemId);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<TodoItem?> deleteItemWithUndo(String listId, String itemId) async {
    final currentLists = state.value;
    final targetList = currentLists?.where((l) => l.id == listId).firstOrNull;
    final targetItem = targetList?.items
        .where((i) => i.id == itemId)
        .firstOrNull;
    if (targetItem == null) return null;

    final updatedLists = currentLists!.map((l) {
      if (l.id == listId) {
        final updatedItems = l.items.where((i) => i.id != itemId).toList();
        return l.copyWith(isSynced: false, items: updatedItems);
      }
      return l;
    }).toList();
    state = AsyncData(updatedLists);

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.deleteItem(listId, itemId);
      return targetItem;
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> restoreItem(TodoItem item) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == item.listId) {
          final items = [...l.items, item];
          items.sort((a, b) => a.position.compareTo(b.position));
          return l.copyWith(isSynced: false, items: items);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.restoreItem(item);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> reorderItems(String listId, int oldIndex, int newIndex) async {
    final currentLists = state.value;
    if (currentLists == null) return;
    final targetList = currentLists.where((l) => l.id == listId).firstOrNull;
    if (targetList == null) return;

    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }

    final updatedItems = List<TodoItem>.from(targetList.items);
    final movedItem = updatedItems.removeAt(oldIndex);
    updatedItems.insert(targetIndex, movedItem);

    final reordered = <TodoItem>[];
    for (var i = 0; i < updatedItems.length; i++) {
      reordered.add(updatedItems[i].copyWith(position: i));
    }

    final updatedLists = currentLists.map((l) {
      if (l.id == listId) {
        return l.copyWith(items: reordered);
      }
      return l;
    }).toList();
    state = AsyncData(updatedLists);

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.reorderItems(
        listId,
        reordered.map((i) => i.id).toList(),
      );
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> addCollaborator(String listId, String email) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.addCollaborator(listId, email);
    state = AsyncData(await repository.getLists());
  }

  Future<void> removeCollaborator(String listId, String collaboratorId) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.removeCollaborator(listId, collaboratorId);
    state = AsyncData(await repository.getLists());
  }

  Future<void> manualSync() async {
    final repository = ref.read(listsRepositoryProvider);
    state = AsyncData(await repository.getLists());
  }
}

final listsControllerProvider =
    AsyncNotifierProvider<ListsController, List<ShoppingList>>(
      ListsController.new,
    );

final shoppingListProvider = Provider.family<ShoppingList?, String>((ref, id) {
  final listsAsync = ref.watch(listsControllerProvider);
  return listsAsync.value?.where((l) => l.id == id).firstOrNull;
});
