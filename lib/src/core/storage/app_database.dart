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
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onOpen: _onOpen,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onOpen(Database db) async {
    await _ensureColumn(
      db,
      'lists',
      'has_invite',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(db, 'lists', 'is_shared', 'INTEGER NOT NULL DEFAULT 0');
    await _ensureColumn(
      db,
      'lists',
      'is_starred',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(db, 'lists', 'position', 'INTEGER NOT NULL DEFAULT 0');
    await _ensureColumn(db, 'items', 'position', 'INTEGER NOT NULL DEFAULT 0');
    await _ensureColumn(
      db,
      'collaborators',
      'role',
      "TEXT NOT NULL DEFAULT 'member'",
    );
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      );
    ''');
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final tableInfo = await db.rawQuery("PRAGMA table_info('$table');");
    final columns = tableInfo.map((col) => col['name'] as String).toSet();
    if (columns.isNotEmpty && !columns.contains(column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition;');
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
        has_invite INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE items (
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
    final defaults = [('Mi lista', 0, 0)];

    for (final (name, isStarred, position) in defaults) {
      await db.insert('lists', {
        'id': uuid.v4(),
        'name': name,
        'is_synced': 1,
        'is_starred': isStarred,
        'is_shared': 0,
        'has_invite': 0,
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
      where: 'key = ?',
      whereArgs: [key],
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
