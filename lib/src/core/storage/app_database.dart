import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite Database manager with offline-first synchronization metadata.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static Database? _database;

  /// Optional override for testing purposes (e.g. inMemoryDatabasePath).
  static String? overrideDbPath;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Resolves the database file path according to the current platform.
  static Future<String> resolveDatabasePath({
    String? override,
    bool isDesktop = false,
    Future<String> Function()? getDocDir,
    Future<String> Function()? getDefaultDatabasesPath,
  }) async {
    if (override != null) return override;
    if (isDesktop) {
      final docPath = await (getDocDir != null
          ? getDocDir()
          : getApplicationSupportDirectory().then((d) => d.path));
      return p.join(docPath, 'listix.db');
    }
    final defaultPath = await (getDefaultDatabasesPath != null
        ? getDefaultDatabasesPath()
        : getDatabasesPath());
    return p.join(defaultPath, 'listix.db');
  }

  Future<Database> _initDatabase() async {
    final isDesktop =
        !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await resolveDatabasePath(
      override: overrideDbPath,
      isDesktop: isDesktop,
    );

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shopping_lists (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE todo_items (
        id TEXT PRIMARY KEY NOT NULL,
        list_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        FOREIGN KEY (list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE collaborators (
        id TEXT PRIMARY KEY NOT NULL,
        list_id TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        is_owner INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_todo_items_list_id ON todo_items(list_id);',
    );
    await db.execute(
      'CREATE INDEX idx_todo_items_is_synced ON todo_items(is_synced);',
    );
    await db.execute(
      'CREATE INDEX idx_shopping_lists_is_synced ON shopping_lists(is_synced);',
    );
    await db.execute(
      'CREATE INDEX idx_collaborators_list_id ON collaborators(list_id);',
    );

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('shopping_lists', {
      'id': 'list-1',
      'name': 'Supermercado semanal',
      'is_synced': 1,
      'created_at': now - 86400000 * 2,
      'updated_at': now - 86400000 * 2,
    });

    await db.insert('collaborators', {
      'id': 'collab-1',
      'list_id': 'list-1',
      'name': 'Mariana Ruiz',
      'email': 'mariana.ruiz@example.com',
      'is_owner': 0,
    });
    await db.insert('collaborators', {
      'id': 'collab-2',
      'list_id': 'list-1',
      'name': 'Carlos Gómez',
      'email': 'carlos.g@example.com',
      'is_owner': 0,
    });

    await db.insert('todo_items', {
      'id': 'item-101',
      'list_id': 'list-1',
      'title': 'Leche deslactosada',
      'is_completed': 0,
      'is_synced': 1,
      'created_at': now - 14400000,
      'updated_at': now - 14400000,
    });
    await db.insert('todo_items', {
      'id': 'item-102',
      'list_id': 'list-1',
      'title': 'Huevos de campo x30',
      'is_completed': 0,
      'is_synced': 1,
      'created_at': now - 10800000,
      'updated_at': now - 10800000,
    });
    await db.insert('todo_items', {
      'id': 'item-103',
      'list_id': 'list-1',
      'title': 'Aguacates maduros',
      'is_completed': 0,
      'is_synced': 0,
      'created_at': now - 7200000,
      'updated_at': now - 7200000,
    });
    await db.insert('todo_items', {
      'id': 'item-104',
      'list_id': 'list-1',
      'title': 'Café en grano tostado',
      'is_completed': 1,
      'is_synced': 1,
      'created_at': now - 86400000,
      'updated_at': now - 86400000,
    });
    await db.insert('todo_items', {
      'id': 'item-105',
      'list_id': 'list-1',
      'title': 'Pan integral de masa madre',
      'is_completed': 1,
      'is_synced': 1,
      'created_at': now - 86400000,
      'updated_at': now - 86400000,
    });

    await db.insert('shopping_lists', {
      'id': 'list-2',
      'name': 'Ferretería y Hogar',
      'is_synced': 1,
      'created_at': now - 86400000 * 4,
      'updated_at': now - 86400000 * 4,
    });
    await db.insert('todo_items', {
      'id': 'item-201',
      'list_id': 'list-2',
      'title': 'Bombillos LED luz cálida',
      'is_completed': 0,
      'is_synced': 1,
      'created_at': now - 36000000,
      'updated_at': now - 36000000,
    });
    await db.insert('todo_items', {
      'id': 'item-202',
      'list_id': 'list-2',
      'title': 'Cinta aislante negra',
      'is_completed': 0,
      'is_synced': 1,
      'created_at': now - 28800000,
      'updated_at': now - 28800000,
    });

    await db.insert('shopping_lists', {
      'id': 'list-3',
      'name': 'Ropa para vacaciones',
      'is_synced': 0,
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
    await db.insert('todo_items', {
      'id': 'item-301',
      'list_id': 'list-3',
      'title': 'Gafas de sol polarizadas',
      'is_completed': 0,
      'is_synced': 0,
      'created_at': now - 2400000,
      'updated_at': now - 2400000,
    });
  }

  /// Closes database instance for resetting state in testing.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
