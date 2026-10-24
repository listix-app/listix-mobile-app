import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_session_service.dart';
import '../../../collaboration/data/repositories/api_collaboration_repository.dart';
import '../../../sync/data/api_sync_service.dart';
import '../../../collaboration/domain/entities/collaboration_event.dart';
import '../../../collaboration/domain/services/invite_token_service.dart';
import '../../../collaboration/presentation/controllers/collaboration_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
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
      if (list != null && !list.canSyncAndShare) {
        return;
      }
      ref
          .read(collaborationControllerProvider.notifier)
          .broadcastEvent(event.listId, event);
    } catch (_) {}
  }

  void _syncIfReady() {
    try {
      final authSession = ref.read(authSessionServiceProvider);
      if (authSession.isReady) {
        ref.read(apiSyncServiceProvider).syncPendingOperations();
      }
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
    await repository.markListInviteCreated(listId);
    await repository.syncList(listId);
    final authSession = ref.read(authSessionServiceProvider);
    if (!authSession.isReady) {
      await authSession.ensureInitialized();
    }
    if (authSession.isReady) {
      // coverage:ignore-start
      try {
        final lists = await repository.getLists();
        final currentList = lists.where((l) => l.id == listId).firstOrNull;
        if (currentList != null) {
          final apiClient = ref.read(apiClientProvider);
          await apiClient.put(
            '/lists/$listId',
            body: {
              'name': currentList.name,
              'isStarred': currentList.isStarred,
              'position': currentList.position < 0 ? 0 : currentList.position,
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            },
          );
        }
      } catch (_) {}
      // coverage:ignore-end
      await ref.read(apiSyncServiceProvider).syncPendingOperations();
    }
    state = AsyncData(await repository.getLists());
  }

  Future<void> setListShared(String listId, bool isShared) async {
    final repository = ref.read(listsRepositoryProvider);
    await repository.setListShared(listId, isShared);
    if (isShared) {
      final currentList = (await repository.getLists())
          .where((l) => l.id == listId)
          .firstOrNull;
      if (currentList != null && currentList.canSyncAndShare) {
        await repository.syncList(listId);
        if (ref.read(authSessionServiceProvider).isReady) {
          await ref.read(apiSyncServiceProvider).syncPendingOperations();
        }
      }
    }
    state = AsyncData(await repository.getLists());
  }

  Future<ShoppingList> createList(String name, {int? color}) async {
    final repository = ref.read(listsRepositoryProvider);
    final created = await repository.createList(name, color: color);
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

  Future<ShoppingList> joinListByInviteToken(
    String tokenOrUrl, {
    String? displayName,
    String? email,
  }) async {
    final authSession = ref.read(authSessionServiceProvider);
    if (!authSession.isReady) {
      await authSession.ensureInitialized();
    }

    if (authSession.isReady) {
      final apiCollab = ref.read(apiCollaborationRepositoryProvider);
      final joinResult = await apiCollab.joinListByToken(
        tokenOrUrl: tokenOrUrl,
        displayName: displayName,
        email: email,
      );
      final repository = ref.read(listsRepositoryProvider);
      await repository.saveRemoteList(joinResult.list);
      state = AsyncData(await repository.getLists());

      ref.read(apiSyncServiceProvider).subscribeToList(joinResult.list.id);
      return joinResult.list;
    }

    final cleanId =
        InviteTokenService.extractToken(tokenOrUrl) ?? tokenOrUrl.trim();
    return await joinList(cleanId, 'Lista Compartida');
  }

  Future<void> updateListName(String id, String newName, {int? color}) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == id) {
          return l.copyWith(
            name: newName.trim(),
            color: color ?? l.color,
            isSynced: false,
          );
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.updateListName(id, newName, color: color);
      _syncIfReady();
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> archiveList(String id) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == id) {
          return l.copyWith(isArchived: true);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.archiveList(id);
      _syncIfReady();
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> unarchiveList(String id) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == id) {
          return l.copyWith(isArchived: false);
        }
        return l;
      }).toList();
      state = AsyncData(updatedLists);
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.unarchiveList(id);
      _syncIfReady();
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
      _syncIfReady();
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
      _syncIfReady();
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
      _syncIfReady();
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<List<ShoppingList>> deleteArchivedListsWithUndo() async {
    final currentLists = state.value;
    final archived = currentLists?.where((l) => l.isArchived).toList() ?? [];
    if (archived.isEmpty) return const [];

    state = AsyncData(currentLists!.where((l) => !l.isArchived).toList());

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.deleteArchivedLists();
      _syncIfReady();
      return archived;
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> restoreLists(List<ShoppingList> lists) async {
    if (lists.isEmpty) return;
    final currentLists = state.value ?? [];
    final updatedLists = [...currentLists, ...lists];
    updatedLists.sort((a, b) {
      if (a.isStarred != b.isStarred) {
        return a.isStarred ? -1 : 1;
      }
      return a.position.compareTo(b.position);
    });
    state = AsyncData(updatedLists);

    try {
      final repository = ref.read(listsRepositoryProvider);
      for (final list in lists) {
        await repository.restoreList(list);
      }
      _syncIfReady();
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
      _syncIfReady();
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
      _syncIfReady();
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
      if (!ref.mounted) return;

      _broadcastEvent(
        CollaborationEvent.itemAdded(
          listId: listId,
          item: optimisticItem,
          senderEmail: _getCurrentEmail(),
          senderName: _getCurrentName(),
        ),
      );
      _syncIfReady();
      final list = targetList;
      final isShared =
          (list?.isShared ?? false) || (list?.canSyncAndShare ?? false);
      final notificationsActive = ref
          .read(notificationsControllerProvider)
          .isEnabled;
      final isOffline = ref.read(syncControllerProvider.notifier).isOffline;
      if (notificationsActive && isShared && !isOffline) {
        final listName = list?.name ?? 'Lista';
        try {
          await ref
              .read(notificationsControllerProvider.notifier)
              .showItemNotification(
                listName: listName,
                itemTitle: title.trim(),
              );
        } catch (_) {}
      }
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> updateItem(String listId, String itemId, String newTitle) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedItems = l.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(title: newTitle.trim(), isSynced: false);
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
      await repository.updateItemTitle(listId, itemId, newTitle);
      _broadcastEvent(
        CollaborationEvent.itemUpdated(
          listId: listId,
          itemId: itemId,
          title: newTitle.trim(),
          senderEmail: _getCurrentEmail(),
          senderName: _getCurrentName(),
        ),
      );
      _syncIfReady();
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
      _syncIfReady();
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
      _syncIfReady();
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
      _syncIfReady();
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
      _syncIfReady();
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<List<TodoItem>> deleteCompletedItemsWithUndo(String listId) async {
    final currentLists = state.value;
    final targetList = currentLists?.where((l) => l.id == listId).firstOrNull;
    if (targetList == null) return const [];
    final completedItems = targetList.items
        .where((i) => i.isCompleted)
        .toList();
    if (completedItems.isEmpty) return const [];

    final updatedLists = currentLists!.map((l) {
      if (l.id == listId) {
        final remaining = l.items.where((i) => !i.isCompleted).toList();
        return l.copyWith(isSynced: false, items: remaining);
      }
      return l;
    }).toList();
    state = AsyncData(updatedLists);

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.deleteCompletedItems(listId);
      for (final item in completedItems) {
        _broadcastEvent(
          CollaborationEvent.itemDeleted(
            listId: listId,
            itemId: item.id,
            senderEmail: _getCurrentEmail(),
            senderName: _getCurrentName(),
          ),
        );
      }
      _syncIfReady();
      return completedItems;
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  Future<void> restoreItems(String listId, List<TodoItem> items) async {
    if (items.isEmpty) return;
    final currentLists = state.value ?? [];
    final updatedLists = currentLists.map((l) {
      if (l.id == listId) {
        final merged = [...l.items, ...items];
        merged.sort((a, b) => a.position.compareTo(b.position));
        return l.copyWith(isSynced: false, items: merged);
      }
      return l;
    }).toList();
    state = AsyncData(updatedLists);

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.restoreItems(items);
      for (final item in items) {
        _broadcastEvent(
          CollaborationEvent.itemAdded(
            listId: listId,
            item: item,
            senderEmail: _getCurrentEmail(),
            senderName: _getCurrentName(),
          ),
        );
      }
      _syncIfReady();
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

    final pending = targetList.items.where((i) => !i.isCompleted).toList();
    final completed = targetList.items.where((i) => i.isCompleted).toList();

    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }

    if (oldIndex < 0 ||
        oldIndex >= pending.length ||
        targetIndex < 0 ||
        targetIndex >= pending.length) {
      return;
    }
    final movedItem = pending.removeAt(oldIndex);
    pending.insert(targetIndex, movedItem);
    final allItems = [...pending, ...completed];

    final reordered = <TodoItem>[];
    for (var i = 0; i < allItems.length; i++) {
      reordered.add(allItems[i].copyWith(position: i));
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
      _syncIfReady();
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
    final cleanEmail = email.trim();
    final currentLists = state.value;
    final targetList = currentLists?.where((l) => l.id == listId).firstOrNull;

    if (targetList != null &&
        targetList.collaborators.any(
          (c) => c.email.toLowerCase() == cleanEmail.toLowerCase(),
        )) {
      return;
    }

    try {
      final repository = ref.read(listsRepositoryProvider);
      await repository.addCollaborator(listId, cleanEmail, role: role);
      final freshLists = await repository.getLists();
      state = AsyncData(freshLists);

      final currentList = freshLists.where((l) => l.id == listId).firstOrNull;
      final addedCollab = currentList?.collaborators
          .where((c) => c.email.toLowerCase() == cleanEmail.toLowerCase())
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
    } catch (_) {
      final repository = ref.read(listsRepositoryProvider);
      state = AsyncData(await repository.getLists());
      rethrow;
    }
  }

  /// High-level method to invite a collaborator: sets list shared, adds collaborator in SQLite,
  /// marks sync, updates Riverpod state, and broadcasts realtime event.
  Future<void> inviteCollaborator(
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

  Future<void> applyRemoteItemUpdate(
    String listId,
    String itemId,
    String newTitle,
  ) async {
    final currentLists = state.value;
    if (currentLists != null) {
      final updatedLists = currentLists.map((l) {
        if (l.id == listId) {
          final updatedItems = l.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(title: newTitle.trim());
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
      await repository.applyRemoteItemUpdate(listId, itemId, newTitle);
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
