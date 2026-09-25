import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  @visibleForTesting
  static String? overrideDbPath;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  @visibleForTesting
  static Future<String> resolveDatabasePath({
    String? override,
    Future<String> Function()? getDefaultDatabasesPath,
  }) async {
    if (override != null) {
      return override;
    }

    final dbDirPath = getDefaultDatabasesPath != null
        ? await getDefaultDatabasesPath()
        : await getDatabasesPath();
    return p.join(dbDirPath, 'listix.db');
  }

  Future<Database> _initDatabase() async {
    final dbPath = await resolveDatabasePath(override: overrideDbPath);

    return await openDatabase(
      dbPath,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE shopping_lists ADD COLUMN is_starred INTEGER NOT NULL DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE shopping_lists ADD COLUMN position INTEGER NOT NULL DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE todo_items ADD COLUMN position INTEGER NOT NULL DEFAULT 0;',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL
        );
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE shopping_lists ADD COLUMN is_shared INTEGER NOT NULL DEFAULT 0;',
      );
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS collaborators (
          id TEXT PRIMARY KEY NOT NULL,
          list_id TEXT NOT NULL,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          is_owner INTEGER NOT NULL DEFAULT 0,
          role TEXT NOT NULL DEFAULT 'member',
          FOREIGN KEY (list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE
        );
      ''');
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info('collaborators');",
      );
      final hasRole = tableInfo.any((col) => col['name'] == 'role');
      if (!hasRole) {
        await db.execute(
          "ALTER TABLE collaborators ADD COLUMN role TEXT NOT NULL DEFAULT 'member';",
        );
      }
      await db.execute(
        "UPDATE collaborators SET role = 'owner' WHERE is_owner = 1;",
      );
    }
    if (oldVersion < 6) {
      final masterTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table';",
      );
      final tableNames = masterTables.map((t) => t['name'] as String).toSet();

      if (tableNames.contains('shopping_lists') &&
          !tableNames.contains('lists')) {
        await db.execute('ALTER TABLE shopping_lists RENAME TO lists;');
      }
      if (tableNames.contains('todo_items') && !tableNames.contains('items')) {
        await db.execute('ALTER TABLE todo_items RENAME TO items;');
      }
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_operations (
          id TEXT PRIMARY KEY NOT NULL,
          list_id TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          op_type TEXT NOT NULL,
          payload TEXT,
          created_at INTEGER NOT NULL
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pending_ops_list ON pending_operations(list_id);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pending_ops_created ON pending_operations(created_at);',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        "UPDATE lists SET is_shared = 0 WHERE id IN ('list-1', 'list-3')",
      );
      await db.execute(
        "DELETE FROM pending_operations WHERE list_id IN ('list-1', 'list-3')",
      );
    }
    if (oldVersion < 9) {
      await db.delete(
        'pending_operations',
        where: 'list_id IN (?, ?, ?)',
        whereArgs: ['list-1', 'list-2', 'list-3'],
      );
      await db.delete(
        'lists',
        where: 'id IN (?, ?, ?)',
        whereArgs: ['list-1', 'list-2', 'list-3'],
      );
      await _seedInitialData(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lists (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        is_starred INTEGER NOT NULL DEFAULT 0,
        is_shared INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await db.execute('''CREATE TABLE items (
        id TEXT PRIMARY KEY NOT NULL,
        list_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        FOREIGN KEY (list_id) REFERENCES lists (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE collaborators (
        id TEXT PRIMARY KEY NOT NULL,
        list_id TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        is_owner INTEGER NOT NULL DEFAULT 0,
        role TEXT NOT NULL DEFAULT 'member',
        FOREIGN KEY (list_id) REFERENCES lists (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_operations (
        id TEXT PRIMARY KEY NOT NULL,
        list_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op_type TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('CREATE INDEX idx_items_list_id ON items(list_id);');
    await db.execute('CREATE INDEX idx_items_is_synced ON items(is_synced);');
    await db.execute('CREATE INDEX idx_lists_is_synced ON lists(is_synced);');
    await db.execute('CREATE INDEX idx_lists_is_shared ON lists(is_shared);');
    await db.execute(
      'CREATE INDEX idx_collaborators_list_id ON collaborators(list_id);',
    );
    await db.execute(
      'CREATE INDEX idx_pending_ops_list ON pending_operations(list_id);',
    );
    await db.execute(
      'CREATE INDEX idx_pending_ops_created ON pending_operations(created_at);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      );
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uuid = const Uuid();
    final defaults = [('Mi lista', 1, 0), ('Otra lista', 0, 1)];

    for (final (name, isStarred, position) in defaults) {
      await db.insert('lists', {
        'id': uuid.v4(),
        'name': name,
        'is_synced': 1,
        'is_starred': isStarred,
        'is_shared': 0,
        'position': position,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> enqueuePendingOperation({
    required String id,
    required String listId,
    required String entityType,
    required String entityId,
    required String opType,
    Map<String, dynamic>? payload,
    int? createdAt,
  }) async {
    final db = await database;
    await db.insert('pending_operations', {
      'id': id,
      'list_id': listId,
      'entity_type': entityType,
      'entity_id': entityId,
      'op_type': opType,
      // coverage:ignore-start
      'payload': payload != null ? jsonEncode(payload) : null,
      // coverage:ignore-end
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingOperations({
    String? listId,
  }) async {
    final db = await database;
    if (listId != null) {
      return await db.query(
        'pending_operations',
        where: 'list_id = ?',
        whereArgs: [listId],
        orderBy: 'created_at ASC',
      );
    }
    return await db.query('pending_operations', orderBy: 'created_at ASC');
  }

  Future<void> removePendingOperation(String id) async {
    final db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearPendingOperationsForList(String listId) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
