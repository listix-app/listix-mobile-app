import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/todo_item.dart';
import '../../domain/repositories/lists_repository.dart';

class SqliteListsRepository implements ListsRepository {
  final AppDatabase _appDatabase;
  static const _uuid = Uuid();

  SqliteListsRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db => _appDatabase.database;

  @override
  Future<List<ShoppingList>> getLists() async {
    final db = await _db;

    final listMaps = await db.query(
      'shopping_lists',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );

    if (listMaps.isEmpty) return [];

    final listIds = listMaps.map((m) => m['id'] as String).toList();
    final inPlaceholders = List.filled(listIds.length, '?').join(',');

    final itemMaps = await db.query(
      'todo_items',
      where: 'list_id IN ($inPlaceholders) AND deleted_at IS NULL',
      whereArgs: listIds,
      orderBy: 'created_at DESC',
    );

    final collabMaps = await db.query(
      'collaborators',
      where: 'list_id IN ($inPlaceholders)',
      whereArgs: listIds,
    );

    final itemsByList = <String, List<TodoItem>>{};
    for (final row in itemMaps) {
      final listId = row['list_id'] as String;
      final item = TodoItem(
        id: row['id'] as String,
        listId: listId,
        title: row['title'] as String,
        isCompleted: (row['is_completed'] as int) == 1,
        isSynced: (row['is_synced'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
      );
      itemsByList.putIfAbsent(listId, () => []).add(item);
    }

    final collabsByList = <String, List<Collaborator>>{};
    for (final row in collabMaps) {
      final listId = row['list_id'] as String;
      final collab = Collaborator(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String,
        isOwner: (row['is_owner'] as int) == 1,
      );
      collabsByList.putIfAbsent(listId, () => []).add(collab);
    }

    return listMaps.map((row) {
      final id = row['id'] as String;
      return ShoppingList(
        id: id,
        name: row['name'] as String,
        isSynced: (row['is_synced'] as int) == 1,
        items: itemsByList[id] ?? [],
        collaborators: collabsByList[id] ?? [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
      );
    }).toList();
  }

  @override
  Future<ShoppingList?> getListById(String id) async {
    final lists = await getLists();
    try {
      return lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ShoppingList> createList(String name) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();

    await db.insert('shopping_lists', {
      'id': id,
      'name': name.trim(),
      'is_synced': 0, // Pending sync until shared
      'created_at': now,
      'updated_at': now,
    });

    return ShoppingList(
      id: id,
      name: name.trim(),
      isSynced: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      items: const [],
      collaborators: const [],
    );
  }

  @override
  Future<ShoppingList> updateListName(String id, String newName) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'shopping_lists',
      {'name': newName.trim(), 'is_synced': 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );

    final updated = await getListById(id);
    if (updated == null) throw Exception('Lista no encontrada tras actualizar');
    return updated;
  }

  @override
  Future<void> deleteList(String id) async {
    final db = await _db;
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<TodoItem> addItem(String listId, String title, {String? id}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final itemId = id ?? _uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('todo_items', {
        'id': itemId,
        'list_id': listId,
        'title': title.trim(),
        'is_completed': 0,
        'is_synced': 0,
        'created_at': now,
        'updated_at': now,
      });

      await txn.update(
        'shopping_lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });

    return TodoItem(
      id: itemId,
      listId: listId,
      title: title.trim(),
      isCompleted: false,
      isSynced: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  @override
  Future<TodoItem> toggleItemCompletion(String listId, String itemId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await db.query(
      'todo_items',
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );

    if (existing.isEmpty) throw Exception('Item no encontrado');

    final currentCompleted = (existing.first['is_completed'] as int) == 1;
    final newCompleted = !currentCompleted;

    await db.transaction((txn) async {
      await txn.update(
        'todo_items',
        {
          'is_completed': newCompleted ? 1 : 0,
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      await txn.update(
        'shopping_lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });

    return TodoItem(
      id: itemId,
      listId: listId,
      title: existing.first['title'] as String,
      isCompleted: newCompleted,
      isSynced: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        existing.first['created_at'] as int,
      ),
    );
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete('todo_items', where: 'id = ?', whereArgs: [itemId]);

      await txn.update(
        'shopping_lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });
  }

  @override
  Future<void> addCollaborator(String listId, String email) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanEmail = email.trim();
    final name = cleanEmail.split('@').first;
    final formattedName = name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : 'Colaborador';

    await db.transaction((txn) async {
      await txn.insert('collaborators', {
        'id': _uuid.v4(),
        'list_id': listId,
        'name': formattedName,
        'email': cleanEmail,
        'is_owner': 0,
      });

      await txn.update(
        'shopping_lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });
  }

  @override
  Future<void> removeCollaborator(String listId, String collaboratorId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'collaborators',
        where: 'id = ? AND list_id = ?',
        whereArgs: [collaboratorId, listId],
      );

      await txn.update(
        'shopping_lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });
  }

  @override
  Future<void> syncList(String listId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.update(
        'shopping_lists',
        {'is_synced': 1, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );

      await txn.update(
        'todo_items',
        {'is_synced': 1, 'updated_at': now},
        where: 'list_id = ?',
        whereArgs: [listId],
      );
    });
  }
}
