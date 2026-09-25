import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../collaboration/data/repositories/supabase_collaboration_repository.dart';
import '../../../collaboration/domain/entities/collaboration_event.dart';
import '../../../collaboration/domain/services/invite_token_service.dart';
import '../../../collaboration/presentation/controllers/collaboration_controller.dart';
import '../../../sync/presentation/sync_controller.dart';
import '../../data/repositories/sqlite_lists_repository.dart';
import '../../domain/entities/collaborator.dart';
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

  void _broadcastEvent(CollaborationEvent event) {
    try {
      final list = state.value?.where((l) => l.id == event.listId).firstOrNull;
      if (list != null && !list.isShared) {
        return;
      }
      ref
          .read(collaborationControllerProvider.notifier)
          .broadcastEvent(event.listId, event);
    } catch (_) {}
  }

  String _getCurrentEmail() {
    return 'user@listix.local';
  }

  String _getCurrentName() {
    return 'Tú';
  }

  Future<void> syncListOnShare(String listId) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.setListShared(listId, true);
    await repository.syncList(listId);
    // coverage:ignore-start
    if (ref.read(supabaseServiceProvider).isReady) {
      await ref.read(supabaseSyncServiceProvider).syncPendingOperations();
    }
    // coverage:ignore-end
    state = AsyncData(await repository.getLists());
  }

  Future<void> setListShared(String listId, bool isShared) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.setListShared(listId, isShared);
    if (isShared) {
      await repository.syncList(listId);
      // coverage:ignore-start
      if (ref.read(supabaseServiceProvider).isReady) {
        await ref.read(supabaseSyncServiceProvider).syncPendingOperations();
      }
      // coverage:ignore-end
    }
    state = AsyncData(await repository.getLists());
  }

  Future<ShoppingList> createList(String name) async {
    final repository = ref.read(listsRepositoryProvider);
    final created = await repository.createList(name);
    state = AsyncData(await repository.getLists());
    return created;
  }

  Future<ShoppingList> joinList(
    String listId,
    String name, {
    String? ownerName,
    String? ownerEmail,
  }) async {
    final repository = ref.read(listsRepositoryProvider);
    final joined = await repository.joinSharedList(
      listId,
      name,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
    );
    state = AsyncData(await repository.getLists());
    return joined;
  }

  /// Joins a shared list using a secure invitation token or URL via Supabase RPC.
  /// Validates token hash, 5-member limit, downloads list to SQLite, and initializes Realtime.
  Future<ShoppingList> joinListByInviteToken(
    String tokenOrUrl, {
    String? displayName,
    String? email,
  }) async {
    final supabaseService = ref.read(supabaseServiceProvider);

    // coverage:ignore-start
    if (supabaseService.isReady) {
      final supabaseCollab = ref.read(supabaseCollaborationRepositoryProvider);
      final joinResult = await supabaseCollab.joinListByToken(
        tokenOrUrl: tokenOrUrl,
        displayName: displayName,
        email: email,
      );
      final repository = ref.read(listsRepositoryProvider);
      await repository.saveRemoteList(joinResult.list);
      state = AsyncData(await repository.getLists());

      // Start Realtime channel for this list
      ref.read(supabaseSyncServiceProvider).subscribeToList(joinResult.list.id);
      return joinResult.list;
    }
    // coverage:ignore-end

    // Fallback: parse direct token or list id for offline / mock testing
    final cleanId =
        InviteTokenService.extractToken(tokenOrUrl) ?? tokenOrUrl.trim();
    return await joinList(cleanId, 'Lista Compartida');
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
          final updatedItems = [...l.items, optimisticItem];
          return l.copyWith(isSynced: false, items: updatedItems);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.addItem(listId, title, id: itemId);
      _broadcastEvent(
        CollaborationEvent.itemAdded(
          listId: listId,
          item: optimisticItem,
          senderEmail: _getCurrentEmail(),
          senderName: _getCurrentName(),
        ),
      );
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> toggleItem(String listId, String itemId) async {
    final currentLists = state.value;
    bool? newCompleted;

    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedItems = l.items.map((item) {
            if (item.id == itemId) {
              newCompleted = !item.isCompleted;
              return item.copyWith(isCompleted: newCompleted!, isSynced: false);
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
      if (newCompleted != null) {
        _broadcastEvent(
          CollaborationEvent.itemToggled(
            listId: listId,
            itemId: itemId,
            isCompleted: newCompleted!,
            senderEmail: _getCurrentEmail(),
            senderName: _getCurrentName(),
          ),
        );
      }
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
      _broadcastEvent(
        CollaborationEvent.itemDeleted(
          listId: listId,
          itemId: itemId,
          senderEmail: _getCurrentEmail(),
          senderName: _getCurrentName(),
        ),
      );
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
      _broadcastEvent(
        CollaborationEvent.itemDeleted(
          listId: listId,
          itemId: itemId,
          senderEmail: _getCurrentEmail(),
          senderName: _getCurrentName(),
        ),
      );
      return targetItem;
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> restoreItem(TodoItem item) async {
    final currentLists = state.value ?? [];
    final updatedLists = currentLists.map((l) {
      if (l.id == item.listId) {
        final items = [...l.items, item];
        items.sort((a, b) => a.position.compareTo(b.position));
        return l.copyWith(isSynced: false, items: items);
      }
      return l;
    }).toList();
    state = AsyncData(updatedLists);

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.restoreItem(item);
      _broadcastEvent(
        CollaborationEvent.itemAdded(
          listId: item.listId,
          item: item,
          senderEmail: _getCurrentEmail(),
          senderName: _getCurrentName(),
        ),
      );
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

  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  }) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.setListShared(listId, true);
    await repository.addCollaborator(listId, email, role: role);
    await repository.syncList(listId);
    final freshLists = await repository.getLists();
    state = AsyncData(freshLists);

    final currentList = freshLists.where((l) => l.id == listId).firstOrNull;
    final addedCollab = currentList?.collaborators
        .where((c) => c.email.toLowerCase() == email.trim().toLowerCase())
        .firstOrNull;
    if (addedCollab != null) {
      _broadcastEvent(
        CollaborationEvent.collaboratorInvited(
          listId: listId,
          collaborator: addedCollab,
          senderEmail: _getCurrentEmail(),
          senderName: _getCurrentName(),
        ),
      );
    }
  }

  Future<void> removeCollaborator(String listId, String collaboratorId) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.removeCollaborator(listId, collaboratorId);
    state = AsyncData(await repository.getLists());
    _broadcastEvent(
      CollaborationEvent.collaboratorRemoved(
        listId: listId,
        collaboratorId: collaboratorId,
        senderEmail: _getCurrentEmail(),
        senderName: _getCurrentName(),
      ),
    );
  }

  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.updateCollaboratorRole(listId, collaboratorId, role);
    state = AsyncData(await repository.getLists());
    _broadcastEvent(
      CollaborationEvent.collaboratorRoleUpdated(
        listId: listId,
        collaboratorId: collaboratorId,
        role: role,
        senderEmail: _getCurrentEmail(),
        senderName: _getCurrentName(),
      ),
    );
  }

  // --- Remote Synchronization Callbacks (Called by CollaborationController) ---

  Future<void> applyRemoteItem(TodoItem item) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == item.listId) {
          final existingIdx = l.items.indexWhere((i) => i.id == item.id);
          final List<TodoItem> nextItems;
          if (existingIdx >= 0) {
            nextItems = List<TodoItem>.from(l.items);
            nextItems[existingIdx] = item;
          } else {
            nextItems = [...l.items, item];
          }
          return l.copyWith(items: nextItems);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.applyRemoteItem(item);
    } catch (_) {}
  }

  Future<void> applyRemoteItemToggle(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedItems = l.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(isCompleted: isCompleted);
            }
            return item;
          }).toList();
          return l.copyWith(items: updatedItems);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.applyRemoteItemToggle(listId, itemId, isCompleted);
    } catch (_) {}
  }

  Future<void> applyRemoteItemDelete(String listId, String itemId) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedItems = l.items.where((i) => i.id != itemId).toList();
          return l.copyWith(items: updatedItems);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.applyRemoteItemDelete(listId, itemId);
    } catch (_) {}
  }

  Future<void> applyRemoteCollaborator(
    String listId,
    Collaborator collaborator,
  ) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final existingIdx = l.collaborators.indexWhere(
            (c) => c.id == collaborator.id,
          );
          final List<Collaborator> nextCollabs;
          if (existingIdx >= 0) {
            nextCollabs = List<Collaborator>.from(l.collaborators);
            nextCollabs[existingIdx] = collaborator;
          } else {
            nextCollabs = [...l.collaborators, collaborator];
          }
          return l.copyWith(collaborators: nextCollabs);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.applyRemoteCollaborator(listId, collaborator);
    } catch (_) {}
  }

  Future<void> applyRemoteCollaboratorRemove(
    String listId,
    String collaboratorId,
  ) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedCollabs = l.collaborators
              .where((c) => c.id != collaboratorId)
              .toList();
          return l.copyWith(collaborators: updatedCollabs);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.applyRemoteCollaboratorRemove(listId, collaboratorId);
    } catch (_) {}
  }

  Future<void> applyRemoteCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedCollabs = l.collaborators.map((c) {
            if (c.id == collaboratorId) {
              return c.copyWith(role: role);
            }
            return c;
          }).toList();
          return l.copyWith(collaborators: updatedCollabs);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }
    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.applyRemoteCollaboratorRole(
        listId,
        collaboratorId,
        role,
      );
    } catch (_) {}
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
