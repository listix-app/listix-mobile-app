import '../entities/shopping_list.dart';
import '../entities/todo_item.dart';

abstract interface class ListsRepository {
  Future<List<ShoppingList>> getLists();
  Future<ShoppingList?> getListById(String id);
  Future<ShoppingList> createList(String name);
  Future<ShoppingList> updateListName(String id, String newName);
  Future<void> deleteList(String id);
  Future<void> toggleListStar(String listId);
  Future<void> reorderLists(List<String> orderedListIds);
  Future<void> restoreList(ShoppingList list);

  Future<TodoItem> addItem(String listId, String title, {String? id});
  Future<TodoItem> toggleItemCompletion(String listId, String itemId);
  Future<void> deleteItem(String listId, String itemId);
  Future<void> reorderItems(String listId, List<String> orderedItemIds);
  Future<void> restoreItem(TodoItem item);

  Future<void> addCollaborator(String listId, String email);
  Future<void> removeCollaborator(String listId, String collaboratorId);

  Future<void> syncList(String listId);
}
