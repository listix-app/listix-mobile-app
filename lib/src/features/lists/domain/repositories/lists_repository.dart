import '../entities/collaborator.dart';
import '../entities/list_type.dart';
import '../entities/shopping_list.dart';
import '../entities/todo_item.dart';
import '../../../sync/domain/pending_operation.dart';

abstract interface class ListsRepository {
  Future<List<ShoppingList>> getLists();
  Future<ShoppingList?> getListById(String id);
  Future<ShoppingList> createList(
    String name, {
    int? color,
    ListType type = ListType.custom,
  });
  Future<ShoppingList> updateListName(
    String id,
    String newName, {
    int? color,
    ListType? type,
  });
  Future<void> archiveList(String listId);
  Future<void> unarchiveList(String listId);
  Future<void> deleteList(String id);
  Future<List<ShoppingList>> deleteArchivedLists();
  Future<void> toggleListStar(String listId);
  Future<void> reorderLists(List<String> orderedListIds);
  Future<void> restoreList(ShoppingList list);

  Future<TodoItem> addItem(
    String listId,
    String title, {
    String? id,
    TodoItem? details,
  });
  Future<TodoItem> updateItemDetails(TodoItem item);
  Future<void> toggleChosenItem(String listId, String itemId);
  Future<void> updateListAttributes(String listId, List<String> attributeNames);
  Future<TodoItem> updateItemTitle(
    String listId,
    String itemId,
    String newTitle,
  );
  Future<TodoItem> toggleItemCompletion(String listId, String itemId);
  Future<void> deleteItem(String listId, String itemId);
  Future<List<TodoItem>> deleteCompletedItems(String listId);
  Future<void> reorderItems(String listId, List<String> orderedItemIds);
  Future<void> restoreItem(TodoItem item);
  Future<void> restoreItems(List<TodoItem> items);

  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  });
  Future<void> removeCollaborator(String listId, String collaboratorId);
  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  );
  Future<ShoppingList> joinSharedList(
    String listId,
    String name, {
    String? ownerName,
    String? ownerEmail,
  });

  Future<void> applyRemoteItem(TodoItem item);
  Future<void> applyRemoteItemUpdate(
    String listId,
    String itemId,
    String newTitle,
  );
  Future<void> applyRemoteItemToggle(
    String listId,
    String itemId,
    bool isCompleted,
  );
  Future<void> applyRemoteItemDelete(String listId, String itemId);
  Future<void> applyRemoteCollaborator(
    String listId,
    Collaborator collaborator,
  );
  Future<void> applyRemoteCollaboratorRemove(
    String listId,
    String collaboratorId,
  );
  Future<void> applyRemoteCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  );

  Future<void> syncList(String listId);
  Future<void> setListShared(String listId, bool isShared, {bool? hasInvite});
  Future<void> markListInviteCreated(String listId);

  /// Saves a full remote list and its items into SQLite (used by join and sync engine).
  Future<void> saveRemoteList(ShoppingList list);

  /// Retrieves pending offline operations queued for synchronization.
  Future<List<PendingOperation>> getPendingOperations({String? listId});

  /// Deletes a pending operation once successfully sent to the remote backend.
  Future<void> removePendingOperation(String id);

  /// Clears pending operations for a specific list.
  Future<void> clearPendingOperationsForList(String listId);
}
