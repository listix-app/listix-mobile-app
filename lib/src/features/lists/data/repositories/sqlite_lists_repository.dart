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
      orderBy: 'is_starred DESC, position ASC, created_at DESC',
    );

    if (listMaps.isEmpty) return [];

    final listIds = listMaps.map((m) => m['id'] as String).toList();
    final inPlaceholders = List.filled(listIds.length, '?').join(',');

    final itemMaps = await db.query(
      'todo_items',
      where: 'list_id IN ($inPlaceholders) AND deleted_at IS NULL',
      whereArgs: listIds,
      orderBy: 'position ASC, created_at DESC',
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
        position: (row['position'] as int?) ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
      );
      itemsByList.putIfAbsent(listId, () => []).add(item);
    }

    final collabsByList = <String, List<Collaborator>>{};
    for (final row in collabMaps) {
      final listId = row['list_id'] as String;
      final roleStr = row['role'] as String?;
      final isOwner = (row['is_owner'] as int) == 1;
      final role = roleStr != null
          ? CollaboratorRole.values.firstWhere(
              (r) => r.name == roleStr,
              orElse: () =>
                  isOwner ? CollaboratorRole.owner : CollaboratorRole.member,
            )
          : (isOwner ? CollaboratorRole.owner : CollaboratorRole.member);
      final collab = Collaborator(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String,
        role: role,
        isOwner: isOwner,
      );
      collabsByList.putIfAbsent(listId, () => []).add(collab);
    }

    return listMaps.map((row) {
      final id = row['id'] as String;
      return ShoppingList(
        id: id,
        name: row['name'] as String,
        isSynced: (row['is_synced'] as int) == 1,
        isStarred: (row['is_starred'] as int?) == 1,
        isShared: (row['is_shared'] as int?) == 1,
        position: (row['position'] as int?) ?? 0,
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

    final maxPosQuery = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS max_pos FROM shopping_lists WHERE deleted_at IS NULL',
    );
    final nextPosition = ((maxPosQuery.first['max_pos'] as int?) ?? -1) + 1;

    await db.insert('shopping_lists', {
      'id': id,
      'name': name.trim(),
      'is_synced': 0,
      'is_starred': 0,
      'is_shared': 0,
      'position': nextPosition,
      'created_at': now,
      'updated_at': now,
    });

    return ShoppingList(
      id: id,
      name: name.trim(),
      isSynced: false,
      isStarred: false,
      isShared: false,
      position: nextPosition,
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
  Future<void> toggleListStar(String listId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate(
      'UPDATE shopping_lists SET is_starred = CASE WHEN is_starred = 1 THEN 0 ELSE 1 END, updated_at = ? WHERE id = ?',
      [now, listId],
    );
  }

  @override
  Future<void> reorderLists(List<String> orderedListIds) async {
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < orderedListIds.length; i++) {
      batch.update(
        'shopping_lists',
        {'position': i},
        where: 'id = ?',
        whereArgs: [orderedListIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> restoreList(ShoppingList list) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('shopping_lists', {
        'id': list.id,
        'name': list.name,
        'is_synced': list.isSynced ? 1 : 0,
        'is_starred': list.isStarred ? 1 : 0,
        'is_shared': list.isShared ? 1 : 0,
        'position': list.position,
        'created_at': list.createdAt.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final item in list.items) {
        await txn.insert('todo_items', {
          'id': item.id,
          'list_id': list.id,
          'title': item.title,
          'is_completed': item.isCompleted ? 1 : 0,
          'is_synced': item.isSynced ? 1 : 0,
          'position': item.position,
          'created_at': item.createdAt.millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final collab in list.collaborators) {
        await txn.insert('collaborators', {
          'id': collab.id,
          'list_id': list.id,
          'name': collab.name,
          'email': collab.email,
          'is_owner': collab.isOwner ? 1 : 0,
          'role': collab.role.name,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<TodoItem> addItem(String listId, String title, {String? id}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final itemId = id ?? _uuid.v4();

    final maxPosQuery = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS max_pos FROM todo_items WHERE list_id = ? AND deleted_at IS NULL',
      [listId],
    );
    final nextPosition = ((maxPosQuery.first['max_pos'] as int?) ?? -1) + 1;

    await db.transaction((txn) async {
      await txn.insert('todo_items', {
        'id': itemId,
        'list_id': listId,
        'title': title.trim(),
        'is_completed': 0,
        'is_synced': 0,
        'position': nextPosition,
        'created_at': now,
        'updated_at': now,
      });

      await txn.update(
        'shopping_lists',
        {'is_shared': 1, 'is_synced': 0, 'updated_at': now},
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
      position: nextPosition,
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
        {'is_shared': 1, 'is_synced': 0, 'updated_at': now},
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
      position: (existing.first['position'] as int?) ?? 0,
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
        {'is_shared': 1, 'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });
  }

  @override
  Future<void> reorderItems(String listId, List<String> orderedItemIds) async {
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < orderedItemIds.length; i++) {
      batch.update(
        'todo_items',
        {'position': i},
        where: 'id = ? AND list_id = ?',
        whereArgs: [orderedItemIds[i], listId],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> restoreItem(TodoItem item) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert('todo_items', {
        'id': item.id,
        'list_id': item.listId,
        'title': item.title,
        'is_completed': item.isCompleted ? 1 : 0,
        'is_synced': 0,
        'position': item.position,
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.update(
        'shopping_lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [item.listId],
      );
    });
  }

  @override
  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  }) async {
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
        'is_owner': role == CollaboratorRole.owner ? 1 : 0,
        'role': role.name,
      });

      await txn.update(
        'shopping_lists',
        {'is_shared': 1, 'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });
  }

  @override
  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.update(
        'collaborators',
        {'role': role.name, 'is_owner': role == CollaboratorRole.owner ? 1 : 0},
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
        {'is_shared': 1, 'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );
    });
  }

  @override
  Future<ShoppingList> joinSharedList(
    String listId,
    String name, {
    String? ownerName,
    String? ownerEmail,
  }) async {
    final db = await _db;
    final existing = await getListById(listId);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert('shopping_lists', {
        'id': listId,
        'name': name.trim().isEmpty ? 'Lista compartida' : name.trim(),
        'is_synced': 1,
        'is_starred': 0,
        'is_shared': 1,
        'position': 0,
        'created_at': now,
        'updated_at': now,
        'deleted_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      if (ownerEmail != null && ownerEmail.isNotEmpty) {
        await txn.insert('collaborators', {
          'id': _uuid.v4(),
          'list_id': listId,
          'name': ownerName ?? ownerEmail.split('@').first,
          'email': ownerEmail,
          'is_owner': 1,
          'role': CollaboratorRole.owner.name,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });

    final created = await getListById(listId);
    return created!;
  }

  @override
  Future<void> applyRemoteItem(TodoItem item) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('todo_items', {
      'id': item.id,
      'list_id': item.listId,
      'title': item.title,
      'is_completed': item.isCompleted ? 1 : 0,
      'is_synced': 1,
      'position': item.position,
      'created_at': item.createdAt.millisecondsSinceEpoch,
      'updated_at': now,
      'deleted_at': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> applyRemoteItemToggle(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'todo_items',
      {'is_completed': isCompleted ? 1 : 0, 'is_synced': 1, 'updated_at': now},
      where: 'id = ? AND list_id = ?',
      whereArgs: [itemId, listId],
    );
  }

  @override
  Future<void> applyRemoteItemDelete(String listId, String itemId) async {
    final db = await _db;
    await db.delete(
      'todo_items',
      where: 'id = ? AND list_id = ?',
      whereArgs: [itemId, listId],
    );
  }

  @override
  Future<void> applyRemoteCollaborator(
    String listId,
    Collaborator collaborator,
  ) async {
    final db = await _db;
    await db.insert('collaborators', {
      'id': collaborator.id,
      'list_id': listId,
      'name': collaborator.name,
      'email': collaborator.email,
      'is_owner': collaborator.isOwner ? 1 : 0,
      'role': collaborator.role.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> applyRemoteCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    final db = await _db;
    await db.update(
      'collaborators',
      {'role': role.name, 'is_owner': role == CollaboratorRole.owner ? 1 : 0},
      where: 'id = ? AND list_id = ?',
      whereArgs: [collaboratorId, listId],
    );
  }

  @override
  Future<void> applyRemoteCollaboratorRemove(
    String listId,
    String collaboratorId,
  ) async {
    final db = await _db;
    await db.delete(
      'collaborators',
      where: 'id = ? AND list_id = ?',
      whereArgs: [collaboratorId, listId],
    );
  }

  @override
  Future<void> syncList(String listId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.update(
        'shopping_lists',
        {'is_synced': 1, 'is_shared': 1, 'updated_at': now},
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

  @override
  Future<void> setListShared(String listId, bool isShared) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'shopping_lists',
      {'is_shared': isShared ? 1 : 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }
}
