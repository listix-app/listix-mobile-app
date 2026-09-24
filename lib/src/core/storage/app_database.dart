import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
      version: 6,
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
        CREATE TABLE IF NOT EXISTS app_settings (\n          key TEXT PRIMARY KEY NOT NULL,\n          value TEXT NOT NULL\n        );
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
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lists (\n        id TEXT PRIMARY KEY NOT NULL,
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

    await db.execute('CREATE INDEX idx_items_list_id ON items(list_id);');
    await db.execute('CREATE INDEX idx_items_is_synced ON items(is_synced);');
    await db.execute('CREATE INDEX idx_lists_is_synced ON lists(is_synced);');
    await db.execute('CREATE INDEX idx_lists_is_shared ON lists(is_shared);');
    await db.execute(
      'CREATE INDEX idx_collaborators_list_id ON collaborators(list_id);',
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

    await db.insert('lists', {
      'id': 'list-1',
      'name': 'Supermercado semanal',
      'is_synced': 1,
      'is_starred': 1,
      'is_shared': 1,
      'position': 0,
      'created_at': now - 86400000 * 2,
      'updated_at': now - 86400000 * 2,
    });

    await db.insert('collaborators', {
      'id': 'collab-1',
      'list_id': 'list-1',
      'name': 'Mariana Ruiz',
      'email': 'mariana.ruiz@example.com',
      'is_owner': 0,
      'role': 'admin',
    });
    await db.insert('collaborators', {
      'id': 'collab-2',
      'list_id': 'list-1',
      'name': 'Carlos Gómez',
      'email': 'carlos.g@example.com',
      'is_owner': 0,
    });

    await db.insert('items', {
      'id': 'item-101',
      'list_id': 'list-1',
      'title': 'Leche deslactosada',
      'is_completed': 0,
      'is_synced': 1,
      'position': 0,
      'created_at': now - 14400000,
      'updated_at': now - 14400000,
    });
    await db.insert('items', {
      'id': 'item-102',
      'list_id': 'list-1',
      'title': 'Huevos de campo x30',
      'is_completed': 0,
      'is_synced': 1,
      'position': 1,
      'created_at': now - 10800000,
      'updated_at': now - 10800000,
    });
    await db.insert('items', {
      'id': 'item-103',
      'list_id': 'list-1',
      'title': 'Aguacates maduros',
      'is_completed': 0,
      'is_synced': 0,
      'position': 2,
      'created_at': now - 7200000,
      'updated_at': now - 7200000,
    });
    await db.insert('items', {
      'id': 'item-104',
      'list_id': 'list-1',
      'title': 'Café en grano tostado',
      'is_completed': 1,
      'is_synced': 1,
      'position': 3,
      'created_at': now - 86400000,
      'updated_at': now - 86400000,
    });
    await db.insert('items', {
      'id': 'item-105',
      'list_id': 'list-1',
      'title': 'Pan integral de masa madre',
      'is_completed': 1,
      'is_synced': 1,
      'position': 4,
      'created_at': now - 86400000,
      'updated_at': now - 86400000,
    });

    await db.insert('lists', {
      'id': 'list-2',
      'name': 'Ferretería y Hogar',
      'is_synced': 1,
      'is_starred': 0,
      'is_shared': 0,
      'position': 1,
      'created_at': now - 86400000 * 4,
      'updated_at': now - 86400000 * 4,
    });
    await db.insert('items', {
      'id': 'item-201',
      'list_id': 'list-2',
      'title': 'Bombillos LED 12W x4',
      'is_completed': 0,
      'is_synced': 1,
      'position': 0,
      'created_at': now - 172800000,
      'updated_at': now - 172800000,
    });
    await db.insert('items', {
      'id': 'item-202',
      'list_id': 'list-2',
      'title': 'Cinta de enmascarar',
      'is_completed': 1,
      'is_synced': 1,
      'position': 1,
      'created_at': now - 172800000,
      'updated_at': now - 172800000,
    });

    await db.insert('lists', {
      'id': 'list-3',
      'name': 'Ropa para vacaciones',
      'is_synced': 0,
      'is_starred': 0,
      'is_shared': 1,
      'position': 2,
      'created_at': now - 3600000,
      'updated_at': now - 3600000,
    });
    await db.insert('collaborators', {
      'id': 'collab-3',
      'list_id': 'list-3',
      'name': 'Andrea Morales',
      'email': 'andrea.m@example.com',
      'is_owner': 0,
    });
    await db.insert('items', {
      'id': 'item-301',
      'list_id': 'list-3',
      'title': 'Gafas de sol polarizadas',
      'is_completed': 0,
      'is_synced': 0,
      'position': 0,
      'created_at': now - 2400000,
      'updated_at': now - 2400000,
    });
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
