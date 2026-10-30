import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/storage/app_database.dart';
import '../../../lists/domain/entities/collaborator.dart';
import '../../../lists/domain/entities/shopping_list.dart';
import '../../../lists/data/mappers/todo_item_row_mapper.dart';
import '../../../lists/domain/entities/list_type.dart';
import '../../../lists/domain/entities/todo_item.dart';
import '../../domain/entities/backup_result.dart';
import '../../domain/failures/backup_failure.dart';

abstract interface class BackupLocalDataSource {
  Future<List<ShoppingList>> fetchAllLists();
  Future<BackupImportResult> restoreLists(
    List<ShoppingList> lists, {
    required bool replaceExisting,
  });
}

class BackupLocalDataSourceImpl implements BackupLocalDataSource {
  final Future<Database> _db;

  BackupLocalDataSourceImpl({Future<Database>? db})
    : _db = db ?? AppDatabase.instance.database;

  @override
  Future<List<ShoppingList>> fetchAllLists() async {
    try {
      final db = await _db;
      final listsData = await db.query(
        'lists',
        where: 'deleted_at IS NULL',
        orderBy: 'position ASC, created_at DESC',
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
            .add(TodoItemRowMapper.fromRow(item));
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

      return listsData.map((row) {
        final id = row['id'] as String;
        return ShoppingList(
          id: id,
          name: row['name'] as String,
          type: ListType.fromName(row['list_type'] as String?),
          attributeNames: TodoItemRowMapper.decodeNames(
            row['option_attributes'] as String?,
          ),
          isSynced: (row['is_synced'] as int) == 1,
          isStarred: (row['is_starred'] as int) == 1,
          isShared: (row['is_shared'] as int) == 1,
          hasInvite: (row['has_invite'] as int? ?? 0) == 1,
          position: (row['position'] as int?) ?? 0,
          items: itemsByList[id] ?? [],
          collaborators: collaboratorsByList[id] ?? [],
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int,
          ),
        );
      }).toList();
    } catch (e) {
      throw BackupFailure('Error reading lists from database: $e');
    }
  }

  @override
  Future<BackupImportResult> restoreLists(
    List<ShoppingList> lists, {
    required bool replaceExisting,
  }) async {
    try {
      final db = await _db;
      var totalItems = 0;

      await db.transaction((txn) async {
        if (replaceExisting) {
          await txn.delete('items');
          await txn.delete('collaborators');
          await txn.delete('lists');
        }

        final now = DateTime.now().millisecondsSinceEpoch;

        for (final list in lists) {
          if (!replaceExisting) {
            await txn.delete(
              'items',
              where: 'list_id = ?',
              whereArgs: [list.id],
            );
            await txn.delete(
              'collaborators',
              where: 'list_id = ?',
              whereArgs: [list.id],
            );
          }

          await txn.insert('lists', {
            'id': list.id,
            'name': list.name,
            'list_type': list.type.name,
            'option_attributes': TodoItemRowMapper.encodeNames(
              list.attributeNames,
            ),
            'is_synced': list.isSynced ? 1 : 0,
            'is_starred': list.isStarred ? 1 : 0,
            'is_shared': list.isShared ? 1 : 0,
            'has_invite': list.hasInvite ? 1 : 0,
            'position': list.position,
            'created_at': list.createdAt.millisecondsSinceEpoch,
            'updated_at': now,
            'deleted_at': null,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          for (final item in list.items) {
            totalItems++;
            await txn.insert('items', {
              'id': item.id,
              'list_id': list.id,
              'title': item.title,
              ...TodoItemRowMapper.detailColumns(item),
              'is_completed': item.isCompleted ? 1 : 0,
              'is_synced': item.isSynced ? 1 : 0,
              'position': item.position,
              'created_at': item.createdAt.millisecondsSinceEpoch,
              'updated_at': now,
              'deleted_at': null,
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
        }
      });

      return BackupImportResult(
        success: true,
        listsRestored: lists.length,
        itemsRestored: totalItems,
      );
    } catch (e) {
      throw BackupFailure('Error restoring lists to database: $e');
    }
  }
}

final backupLocalDataSourceProvider = Provider<BackupLocalDataSource>((ref) {
  return BackupLocalDataSourceImpl();
});
