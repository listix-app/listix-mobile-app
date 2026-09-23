import '../entities/shopping_list.dart';
import '../entities/todo_item.dart';

abstract interface class ListsRepository {
  Future<List<ShoppingList>> getLists();
  Future<ShoppingList?> getListById(String id);
  Future<ShoppingList> createList(String name);
  Future<ShoppingList> updateListName(String id, String newName);
  Future<void> deleteList(String id);

  Future<TodoItem> addItem(String listId, String title, {String? id});
  Future<TodoItem> toggleItemCompletion(String listId, String itemId);
  Future<void> deleteItem(String listId, String itemId);

  Future<void> addCollaborator(String listId, String email);
  Future<void> removeCollaborator(String listId, String collaboratorId);
}
