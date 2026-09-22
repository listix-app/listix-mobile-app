import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/sqlite_lists_repository.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/todo_item.dart';
import '../../domain/repositories/lists_repository.dart';
import '../../../sync/presentation/sync_controller.dart';

final listsRepositoryProvider = Provider<ListsRepository>((ref) {
  return SqliteListsRepository();
});

class ListsController extends AsyncNotifier<List<ShoppingList>> {
  Timer? _autoSyncDebounce;
  static const _uuid = Uuid();

  @override
  FutureOr<List<ShoppingList>> build() async {
    final repository = ref.read(listsRepositoryProvider);
    return repository.getLists();
  }

  void _triggerBackgroundSync() {
    _autoSyncDebounce?.cancel();
    _autoSyncDebounce = Timer(const Duration(milliseconds: 1200), () async {
      final syncService = ref.read(mockBackendSyncServiceProvider);
      final didSync = await syncService.synchronize();
      if (didSync) {
        final repository = ref.read(listsRepositoryProvider);
        state = AsyncData(await repository.getLists());
      }
    });
  }

  Future<ShoppingList> createList(String name) async {
    final repository = ref.read(listsRepositoryProvider);
    final created = await repository.createList(name);
    state = AsyncData(await repository.getLists());
    _triggerBackgroundSync();
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
    _triggerBackgroundSync();
  }

  Future<void> deleteList(String id) async {
    // Instantaneous optimistic removal (0ms)
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
    _triggerBackgroundSync();
  }

  /// Real-time instantaneous item addition (0ms latency):
  /// 1. Immediately updates Riverpod in-memory state so the item renders on-screen in the exact same frame.
  /// 2. Asynchronously commits the record to SQLite in the background using the same UUID.
  Future<void> addItem(String listId, String title) async {
    final itemId = _uuid.v4();
    final now = DateTime.now();
    final optimisticItem = TodoItem(
      id: itemId,
      listId: listId,
      title: title.trim(),
      isCompleted: false,
      isSynced: false,
      createdAt: now,
    );

    // 1. Instant Real-Time UI Update
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          return l.copyWith(
            isSynced: false,
            items: [optimisticItem, ...l.items],
          );
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    // 2. Persist to SQLite in background
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.addItem(listId, title, id: itemId);
    } catch (_) {
      // Revert if database write fails
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }

    _triggerBackgroundSync();
  }

  /// Real-time instantaneous item toggle (0ms latency)
  Future<void> toggleItem(String listId, String itemId) async {
    // 1. Instant Real-Time UI Update
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

    // 2. Persist to SQLite in background
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.toggleItemCompletion(listId, itemId);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }

    _triggerBackgroundSync();
  }

  /// Real-time instantaneous item deletion (0ms latency)
  Future<void> deleteItem(String listId, String itemId) async {
    // 1. Instant Real-Time UI Update
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

    // 2. Persist to SQLite in background
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.deleteItem(listId, itemId);
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }

    _triggerBackgroundSync();
  }

  Future<void> addCollaborator(String listId, String email) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.addCollaborator(listId, email);
    state = AsyncData(await repository.getLists());
    _triggerBackgroundSync();
  }

  Future<void> removeCollaborator(String listId, String collaboratorId) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.removeCollaborator(listId, collaboratorId);
    state = AsyncData(await repository.getLists());
    _triggerBackgroundSync();
  }

  /// Forces an immediate sync and refreshes state
  Future<void> manualSync() async {
    final syncService = ref.read(mockBackendSyncServiceProvider);
    await syncService.synchronize();
    final repository = ref.read(listsRepositoryProvider);
    state = AsyncData(await repository.getLists());
  }
}

final listsControllerProvider =
    AsyncNotifierProvider<ListsController, List<ShoppingList>>(
      ListsController.new,
    );

/// Provider to get a single shopping list reactively by its ID
final shoppingListProvider = Provider.family<ShoppingList?, String>((ref, id) {
  final listsAsync = ref.watch(listsControllerProvider);
  return listsAsync.value?.where((l) => l.id == id).firstOrNull;
});
