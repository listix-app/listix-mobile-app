// coverage:ignore-file
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/todo_item.dart';
import '../../domain/repositories/lists_repository.dart';
import '../../../sync/domain/pending_operation.dart';

class SqliteListsRepository implements ListsRepository {
  final Future<Database> _db;
  final Uuid _uuid;

  SqliteListsRepository({Future<Database>? db, Uuid? uuid})
    : _db = db ?? AppDatabase.instance.database,
      _uuid = uuid ?? const Uuid();

  Future<bool> _isListShared(DatabaseExecutor executor, String listId) async {
    final res = await executor.query(
      'lists',
      columns: ['is_shared'],
      where: 'id = ?',
      whereArgs: [listId],
      limit: 1,
    );
    if (res.isEmpty) return false;
    return (res.first['is_shared'] as int?) == 1;
  }

  @override
  Future<List<ShoppingList>> getLists() async {
    final db = await _db;

    final listsData = await db.query(
      'lists',
      where: 'deleted_at IS NULL',
      orderBy: 'is_starred DESC, position ASC, created_at DESC',
    );

    if (listsData.isEmpty) return [];

    final listIds = listsData.map((l) => l['id'] as String).toList();
    final placeholders = List.filled(listIds.length, '?').join(',');

    final itemsData = await db.query(
      'items',
      where: 'list_id IN ($placeholders) AND deleted_at IS NULL',
      whereArgs: listIds,
      orderBy: 'position ASC, created_at ASC',
    );

    final collaboratorsData = await db.query(
      'collaborators',
      where: 'list_id IN ($placeholders)',
      whereArgs: listIds,
    );

    final itemsByList = <String, List<TodoItem>>{};
    for (final item in itemsData) {
      final listId = item['list_id'] as String;
      itemsByList
          .putIfAbsent(listId, () => [])
          .add(
            TodoItem(
              id: item['id'] as String,
              listId: listId,
              title: item['title'] as String,
              isCompleted: (item['is_completed'] as int) == 1,
              isSynced: (item['is_synced'] as int) == 1,
              position: (item['position'] as int?) ?? 0,
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                item['created_at'] as int,
              ),
            ),
          );
    }

    final collaboratorsByList = <String, List<Collaborator>>{};
    for (final collab in collaboratorsData) {
      final listId = collab['list_id'] as String;
      final roleStr = collab['role'] as String? ?? 'member';
      final role = CollaboratorRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => CollaboratorRole.member,
      );

      collaboratorsByList
          .putIfAbsent(listId, () => [])
          .add(
            Collaborator(
              id: collab['id'] as String,
              name: collab['name'] as String,
              email: collab['email'] as String,
              isOwner: (collab['is_owner'] as int) == 1,
              role: role,
            ),
          );
    }

    return listsData.map((list) {
      final id = list['id'] as String;
      return ShoppingList(
        id: id,
        name: list['name'] as String,
        isSynced: (list['is_synced'] as int) == 1,
        isStarred: (list['is_starred'] as int) == 1,
        isShared: (list['is_shared'] as int) == 1,
        position: (list['position'] as int?) ?? 0,
        items: itemsByList[id] ?? [],
        collaborators: collaboratorsByList[id] ?? [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          list['created_at'] as int,
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
      'SELECT COALESCE(MAX(position), -1) AS max_pos FROM lists WHERE deleted_at IS NULL',
    );
    final nextPosition = ((maxPosQuery.first['max_pos'] as int?) ?? -1) + 1;

    await db.insert('lists', {
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

    await db.transaction((txn) async {
      await txn.update(
        'lists',
        {'name': newName.trim(), 'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      final isShared = await _isListShared(txn, id);
      if (isShared) {
        await txn.insert('pending_operations', {
          'id': _uuid.v4(),
          'list_id': id,
          'entity_type': PendingEntityType.list.name,
          'entity_id': id,
          'op_type': PendingOpType.upsert.name,
          'payload': jsonEncode({'name': newName.trim(), 'updated_at': now}),
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    final updated = await getListById(id);
    if (updated == null) throw Exception('Lista no encontrada tras actualizar');
    return updated;
  }

  @override
  Future<void> deleteList(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final isShared = await _isListShared(txn, id);
      if (isShared) {
        await txn.insert('pending_operations', {
          'id': _uuid.v4(),
          'list_id': id,
          'entity_type': PendingEntityType.list.name,
          'entity_id': id,
          'op_type': PendingOpType.delete.name,
          'payload': null,
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.delete('lists', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> toggleListStar(String listId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE lists SET is_starred = CASE WHEN is_starred = 1 THEN 0 ELSE 1 END, updated_at = ?, is_synced = 0 WHERE id = ?',
        [now, listId],
      );
      if (await _isListShared(txn, listId)) {
        final row = await txn.query(
          'lists',
          where: 'id = ?',
          whereArgs: [listId],
          limit: 1,
        );
        if (row.isNotEmpty) {
          await txn.insert('pending_operations', {
            'id': _uuid.v4(),
            'list_id': listId,
            'entity_type': PendingEntityType.list.name,
            'entity_id': listId,
            'op_type': PendingOpType.upsert.name,
            'payload': jsonEncode({
              'name': row.first['name'],
              'is_starred': row.first['is_starred'],
              'position': row.first['position'],
              'updated_at': now,
            }),
            'created_at': now,
          });
        }
      }
    });
  }

  @override
  Future<void> reorderLists(List<String> orderedListIds) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedListIds.length; i++) {
        final id = orderedListIds[i];
        await txn.update(
          'lists',
          {'position': i, 'is_synced': 0, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [id],
        );
        if (await _isListShared(txn, id)) {
          final row = await txn.query(
            'lists',
            where: 'id = ?',
            whereArgs: [id],
            limit: 1,
          );
          if (row.isNotEmpty) {
            await txn.insert('pending_operations', {
              'id': _uuid.v4(),
              'list_id': id,
              'entity_type': PendingEntityType.list.name,
              'entity_id': id,
              'op_type': PendingOpType.upsert.name,
              'payload': jsonEncode({
                'name': row.first['name'],
                'is_starred': row.first['is_starred'],
                'position': i,
                'updated_at': now,
              }),
              'created_at': now,
            });
          }
        }
      }
    });
  }

  @override
  Future<void> restoreList(ShoppingList list) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('lists', {
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
        await txn.insert('items', {
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
      'SELECT COALESCE(MAX(position), -1) AS max_pos FROM items WHERE list_id = ? AND deleted_at IS NULL',
      [listId],
    );
    final nextPosition = ((maxPosQuery.first['max_pos'] as int?) ?? -1) + 1;

    await db.transaction((txn) async {
      await txn.insert('items', {
        'id': itemId,
        'list_id': listId,
        'title': title.trim(),
        'is_completed': 0,
        'is_synced': 0,
        'position': nextPosition,
        'created_at': now,
        'updated_at': now,
      });

      final isShared = await _isListShared(txn, listId);
      await txn.update(
        'lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );

      if (isShared) {
        await txn.insert('pending_operations', {
          'id': _uuid.v4(),
          'list_id': listId,
          'entity_type': PendingEntityType.item.name,
          'entity_id': itemId,
          'op_type': PendingOpType.upsert.name,
          'payload': jsonEncode({
            'id': itemId,
            'list_id': listId,
            'title': title.trim(),
            'is_completed': 0,
            'position': nextPosition,
            'created_at': now,
            'updated_at': now,
          }),
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
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
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );

    if (existing.isEmpty) throw Exception('Item no encontrado');

    final currentCompleted = (existing.first['is_completed'] as int) == 1;
    final newCompleted = !currentCompleted;

    await db.transaction((txn) async {
      await txn.update(
        'items',
        {
          'is_completed': newCompleted ? 1 : 0,
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      final isShared = await _isListShared(txn, listId);
      await txn.update(
        'lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );

      if (isShared) {
        await txn.insert('pending_operations', {
          'id': _uuid.v4(),
          'list_id': listId,
          'entity_type': PendingEntityType.item.name,
          'entity_id': itemId,
          'op_type': PendingOpType.upsert.name,
          'payload': jsonEncode({
            'id': itemId,
            'list_id': listId,
            'title': existing.first['title'] as String,
            'is_completed': newCompleted ? 1 : 0,
            'position': (existing.first['position'] as int?) ?? 0,
            'updated_at': now,
          }),
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
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
      await txn.delete('items', where: 'id = ?', whereArgs: [itemId]);

      final isShared = await _isListShared(txn, listId);
      await txn.update(
        'lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );

      if (isShared) {
        await txn.insert('pending_operations', {
          'id': _uuid.v4(),
          'list_id': listId,
          'entity_type': PendingEntityType.item.name,
          'entity_id': itemId,
          'op_type': PendingOpType.delete.name,
          'payload': null,
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<void> reorderItems(String listId, List<String> orderedItemIds) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final isShared = await _isListShared(txn, listId);
      for (var i = 0; i < orderedItemIds.length; i++) {
        final itemId = orderedItemIds[i];
        await txn.update(
          'items',
          {'position': i, 'is_synced': 0, 'updated_at': now},
          where: 'id = ? AND list_id = ?',
          whereArgs: [itemId, listId],
        );
        if (isShared) {
          final rows = await txn.query(
            'items',
            where: 'id = ? AND list_id = ?',
            whereArgs: [itemId, listId],
            limit: 1,
          );
          if (rows.isNotEmpty) {
            final item = rows.first;
            await txn.insert('pending_operations', {
              'id': _uuid.v4(),
              'list_id': listId,
              'entity_type': PendingEntityType.item.name,
              'entity_id': itemId,
              'op_type': PendingOpType.upsert.name,
              'payload': jsonEncode({
                'title': item['title'],
                'is_completed': item['is_completed'],
                'position': i,
                'updated_at': now,
              }),
              'created_at': now,
            });
          }
        }
      }
    });
  }

  @override
  Future<void> restoreItem(TodoItem item) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert('items', {
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
        'lists',
        {'is_synced': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [item.listId],
      );

      final isShared = await _isListShared(txn, item.listId);
      if (isShared) {
        await txn.insert('pending_operations', {
          'id': _uuid.v4(),
          'list_id': item.listId,
          'entity_type': PendingEntityType.item.name,
          'entity_id': item.id,
          'op_type': PendingOpType.upsert.name,
          'payload': jsonEncode({
            'id': item.id,
            'list_id': item.listId,
            'title': item.title,
            'is_completed': item.isCompleted ? 1 : 0,
            'position': item.position,
            'created_at': item.createdAt.millisecondsSinceEpoch,
            'updated_at': now,
          }),
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
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
        'lists',
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
        'lists',
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
        'lists',
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
      await txn.insert('lists', {
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
  Future<void> saveRemoteList(ShoppingList list) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete('items', where: 'list_id = ?', whereArgs: [list.id]);
      await txn.delete(
        'collaborators',
        where: 'list_id = ?',
        whereArgs: [list.id],
      );
      await txn.insert('lists', {
        'id': list.id,
        'name': list.name,
        'is_synced': 1,
        'is_starred': list.isStarred ? 1 : 0,
        'is_shared': 1,
        'position': list.position,
        'created_at': list.createdAt.millisecondsSinceEpoch,
        'updated_at': now,
        'deleted_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Save collaborators
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

      // Save items
      for (final item in list.items) {
        await txn.insert('items', {
          'id': item.id,
          'list_id': list.id,
          'title': item.title,
          'is_completed': item.isCompleted ? 1 : 0,
          'is_synced': 1,
          'position': item.position,
          'created_at': item.createdAt.millisecondsSinceEpoch,
          'updated_at': now,
          'deleted_at': null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<void> applyRemoteItem(TodoItem item) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('items', {
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
      'items',
      {'is_completed': isCompleted ? 1 : 0, 'is_synced': 1, 'updated_at': now},
      where: 'id = ? AND list_id = ?',
      whereArgs: [itemId, listId],
    );
  }

  @override
  Future<void> applyRemoteItemDelete(String listId, String itemId) async {
    final db = await _db;
    await db.delete(
      'items',
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
        'lists',
        {'is_synced': 1, 'is_shared': 1, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );

      await txn.update(
        'items',
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
    await db.transaction((txn) async {
      await txn.update(
        'lists',
        {'is_shared': isShared ? 1 : 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [listId],
      );

      if (isShared) {
        // Enqueue list upsert
        final listQuery = await txn.query(
          'lists',
          where: 'id = ?',
          whereArgs: [listId],
          limit: 1,
        );
        if (listQuery.isNotEmpty) {
          final l = listQuery.first;
          await txn.insert('pending_operations', {
            'id': _uuid.v4(),
            'list_id': listId,
            'entity_type': PendingEntityType.list.name,
            'entity_id': listId,
            'op_type': PendingOpType.upsert.name,
            'payload': jsonEncode({
              'id': listId,
              'name': l['name'] as String,
              'is_starred': l['is_starred'] as int,
              'position': l['position'] as int,
              'updated_at': now,
            }),
            'created_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Also enqueue existing items
          final items = await txn.query(
            'items',
            where: 'list_id = ? AND deleted_at IS NULL',
            whereArgs: [listId],
          );
          for (final item in items) {
            await txn.insert('pending_operations', {
              'id': _uuid.v4(),
              'list_id': listId,
              'entity_type': PendingEntityType.item.name,
              'entity_id': item['id'] as String,
              'op_type': PendingOpType.upsert.name,
              'payload': jsonEncode({
                'id': item['id'] as String,
                'list_id': listId,
                'title': item['title'] as String,
                'is_completed': item['is_completed'] as int,
                'position': item['position'] as int? ?? 0,
                'updated_at': item['updated_at'] as int? ?? now,
              }),
              'created_at': now,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });
  }

  @override
  Future<List<PendingOperation>> getPendingOperations({String? listId}) async {
    final db = await _db;
    final List<Map<String, dynamic>> rows;
    if (listId != null) {
      rows = await db.query(
        'pending_operations',
        where: 'list_id = ?',
        whereArgs: [listId],
        orderBy: 'created_at ASC, rowid ASC',
      );
    } else {
      rows = await db.query(
        'pending_operations',
        orderBy: 'created_at ASC, rowid ASC',
      );
    }
    final sharedListRows = await db.query(
      'lists',
      columns: ['id'],
      where: 'is_shared = 1',
    );
    final sharedListIds = sharedListRows
        .map((row) => row['id'] as String)
        .toSet();
    return rows
        .where((row) => sharedListIds.contains(row['list_id']))
        .map(PendingOperation.fromMap)
        .toList();
  }

  @override
  Future<void> removePendingOperation(String id) async {
    final db = await _db;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearPendingOperationsForList(String listId) async {
    final db = await _db;
    await db.delete(
      'pending_operations',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }
}
