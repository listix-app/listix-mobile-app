import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:listix/src/features/backup/data/datasources/native_file_service.dart';
import 'package:listix/src/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:listix/src/features/backup/domain/entities/backup_data.dart';
import 'package:listix/src/features/backup/domain/entities/backup_result.dart';
import 'package:listix/src/features/backup/domain/failures/backup_failure.dart';
import 'package:listix/src/features/backup/domain/repositories/backup_repository.dart';
import 'package:listix/src/features/backup/presentation/controllers/backup_controller.dart';
import 'package:listix/src/features/backup/presentation/controllers/backup_state.dart';
import 'package:listix/src/features/backup/presentation/screens/backup_screen.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/notifications/data/services/notification_service.dart';
import 'package:listix/src/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:listix/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:listix/src/routing/routes.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeNotificationService implements NotificationService {
  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> scheduleWeeklyReminder({
    required String title,
    required String body,
    int dayOfWeek = DateTime.sunday,
    int hour = 10,
    int minute = 0,
  }) async => true;

  @override
  Future<void> cancelWeeklyReminder() async {}

  @override
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {}
}

class FakeBackupRepository implements BackupRepository {
  BackupData internalData;
  Map<String, dynamic>? mockPickedFile;
  bool shouldThrow = false;
  bool saveShouldFail = false;

  FakeBackupRepository({BackupData? data})
    : internalData =
          data ??
          BackupData(
            version: 1,
            exportedAt: DateTime(2026, 10, 7),
            appVersion: '1.0.0',
            lists: [
              ShoppingList(
                id: 'l1',
                name: 'Test List',
                items: [
                  TodoItem(
                    id: 'i1',
                    listId: 'l1',
                    title: 'Item 1',
                    createdAt: DateTime(2026, 10, 7),
                  ),
                ],
                createdAt: DateTime(2026, 10, 7),
              ),
            ],
          );

  @override
  Future<BackupData> createBackupData() async {
    if (shouldThrow) throw const BackupFailure('Create failed');
    return internalData;
  }

  @override
  Future<String> exportBackupJson() async {
    if (shouldThrow) throw const BackupFailure('Export JSON failed');
    return internalData.toPrettyJson();
  }

  @override
  Future<String> exportBackupCsv() async {
    if (shouldThrow) throw const BackupFailure('Export CSV failed');
    return internalData.toCsv();
  }

  @override
  Future<String> exportPlainTextSummary() async {
    if (shouldThrow) throw const BackupFailure('Export plain text failed');
    return internalData.toPlainTextSummary();
  }

  @override
  Future<BackupData> parseBackupJson(String jsonString) async {
    if (shouldThrow) throw const BackupFailure('Parse failed');
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return BackupData.fromJson(map);
  }

  @override
  Future<BackupImportResult> restoreBackup(
    BackupData backup, {
    bool replaceExisting = false,
  }) async {
    if (shouldThrow) throw const BackupFailure('Restore failed');
    return BackupImportResult(
      success: true,
      listsRestored: backup.totalLists,
      itemsRestored: backup.totalItems,
    );
  }

  @override
  Future<BackupExportResult> saveBackupToFile({
    required String fileName,
    required String content,
    String? mimeType,
  }) async {
    if (shouldThrow) throw const BackupFailure('Save failed');
    if (saveShouldFail) {
      return const BackupExportResult(success: false, message: 'Canceled');
    }
    return BackupExportResult(
      success: true,
      fileName: fileName,
      filePath: '/storage/$fileName',
    );
  }

  @override
  Future<Map<String, dynamic>?> pickBackupFile() async {
    if (shouldThrow) throw const BackupFailure('Pick failed');
    return mockPickedFile;
  }

  @override
  Future<void> shareBackup({
    required String fileName,
    required String content,
    String? mimeType,
    String? subject,
  }) async {
    if (shouldThrow) throw const BackupFailure('Share failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    try {
      if (databaseFactory != databaseFactoryFfi) {
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {
      databaseFactory = databaseFactoryFfi;
    }
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
    await AppDatabase.instance.database;
  });

  group('Backup Domain Entities & Failures', () {
    test('BackupFailure properties, toString, equality and hashCode', () {
      const failure1 = BackupFailure('Disk error');
      const failure2 = BackupFailure('Disk error');
      const failure3 = BackupFailure('Different');

      expect(failure1.message, 'Disk error');
      expect(failure1.toString(), 'BackupFailure: Disk error');
      expect(failure1, equals(failure2));
      expect(failure1 == failure3, isFalse);
      expect(failure1.hashCode, failure2.hashCode);
    });

    test('BackupExportResult equality and hashCode', () {
      const res1 = BackupExportResult(
        success: true,
        fileName: 'a.json',
        filePath: '/p/a.json',
        message: 'ok',
      );
      const res2 = BackupExportResult(
        success: true,
        fileName: 'a.json',
        filePath: '/p/a.json',
        message: 'ok',
      );
      const resDiffName = BackupExportResult(
        success: true,
        fileName: 'b.json',
        filePath: '/p/a.json',
        message: 'ok',
      );
      const resDiffPath = BackupExportResult(
        success: true,
        fileName: 'a.json',
        filePath: '/p/b.json',
        message: 'ok',
      );
      const resDiffMsg = BackupExportResult(
        success: true,
        fileName: 'a.json',
        filePath: '/p/a.json',
        message: 'diff',
      );
      const res3 = BackupExportResult(success: false);

      expect(res1, equals(res2));
      expect(res1 == resDiffName, isFalse);
      expect(res1 == resDiffPath, isFalse);
      expect(res1 == resDiffMsg, isFalse);
      expect(res1 == res3, isFalse);
      expect(res1.hashCode, res2.hashCode);
    });

    test('BackupImportResult equality and hashCode', () {
      const res1 = BackupImportResult(
        success: true,
        listsRestored: 2,
        itemsRestored: 5,
        message: 'done',
      );
      const res2 = BackupImportResult(
        success: true,
        listsRestored: 2,
        itemsRestored: 5,
        message: 'done',
      );
      const resDiffLists = BackupImportResult(
        success: true,
        listsRestored: 3,
        itemsRestored: 5,
        message: 'done',
      );
      const resDiffItems = BackupImportResult(
        success: true,
        listsRestored: 2,
        itemsRestored: 6,
        message: 'done',
      );
      const resDiffMsg = BackupImportResult(
        success: true,
        listsRestored: 2,
        itemsRestored: 5,
        message: 'diff',
      );
      const res3 = BackupImportResult(
        success: false,
        listsRestored: 0,
        itemsRestored: 0,
      );

      expect(res1, equals(res2));
      expect(res1 == resDiffLists, isFalse);
      expect(res1 == resDiffItems, isFalse);
      expect(res1 == resDiffMsg, isFalse);
      expect(res1 == res3, isFalse);
      expect(res1.hashCode, res2.hashCode);
    });

    test('BackupData serialization, formatting and copyWith', () {
      final now = DateTime(2026, 10, 7, 12, 30);
      final list = ShoppingList(
        id: 'l1',
        name: 'Supermercado',
        items: [
          TodoItem(
            id: 'i1',
            listId: 'l1',
            title: 'Leche',
            isCompleted: false,
            createdAt: now,
          ),
          TodoItem(
            id: 'i2',
            listId: 'l1',
            title: 'Huevos',
            isCompleted: true,
            createdAt: now,
          ),
        ],
        collaborators: const [
          Collaborator(
            id: 'c1',
            name: 'Ana',
            email: 'ana@example.com',
            role: CollaboratorRole.admin,
          ),
        ],
        createdAt: now,
      );

      final emptyList = ShoppingList(
        id: 'l2',
        name: 'Vacia',
        items: const [],
        createdAt: now,
      );

      final backup = BackupData(
        version: 1,
        exportedAt: now,
        appVersion: '1.0.0',
        lists: [list, emptyList],
      );

      expect(backup.totalLists, 2);
      expect(backup.totalItems, 2);

      final jsonMap = backup.toJson();
      expect(jsonMap['version'], 1);
      expect(jsonMap['appVersion'], '1.0.0');

      final fromJson = BackupData.fromJson(jsonMap);
      expect(fromJson, equals(backup));
      expect(fromJson.hashCode, backup.hashCode);

      final pretty = backup.toPrettyJson();
      expect(pretty, contains('"version": 1'));

      final summary = backup.toPlainTextSummary();
      expect(summary, contains('# Listix Backup Export'));
      expect(summary, contains('Total lists: 2'));
      expect(summary, contains('Total items: 2'));
      expect(summary, contains('## Supermercado'));
      expect(summary, contains('- [ ] Leche'));
      expect(summary, contains('- [x] Huevos'));
      expect(summary, contains('## Vacia'));
      expect(summary, contains('- (Empty)'));

      final csv = backup.toCsv();
      expect(csv, contains('List,Item,Status,Created At'));
      expect(csv, contains('"Supermercado","Leche","Pending"'));
      expect(csv, contains('"Supermercado","Huevos","Completed"'));
      expect(csv, contains('"Vacia","",""'));

      final specialList = ShoppingList(
        id: 'l_special',
        name: 'List with "quotes" and, commas\nand newlines',
        items: [
          TodoItem(
            id: 'i_special',
            listId: 'l_special',
            title: 'Item "quoted", and, comma',
            createdAt: now,
          ),
        ],
        createdAt: now,
      );
      final specialBackup = BackupData(
        version: 1,
        exportedAt: now,
        appVersion: '1.0.0',
        lists: [specialList],
      );
      final specialCsv = specialBackup.toCsv();
      expect(specialCsv, contains('""quotes"" and, commas'));
      expect(specialCsv, contains('""quoted"", and, comma'));

      final copied = backup.copyWith(
        version: 2,
        appVersion: '2.0.0',
        exportedAt: DateTime(2027),
        lists: [list],
      );
      expect(copied.version, 2);
      expect(copied.appVersion, '2.0.0');
      expect(copied.lists.length, 1);

      final copiedFallback = backup.copyWith();
      expect(copiedFallback, equals(backup));
    });

    test('BackupData.fromJson validations and edge cases', () {
      expect(
        () => BackupData.fromJson({'version': 'invalid'}),
        throwsA(isA<BackupFailure>()),
      );

      expect(
        () => BackupData.fromJson({'version': 1, 'lists': 'not-a-list'}),
        throwsA(isA<BackupFailure>()),
      );

      expect(
        () => BackupData.fromJson({
          'version': 1,
          'lists': ['not-a-map'],
        }),
        throwsA(isA<BackupFailure>()),
      );

      expect(
        () => BackupData.fromJson({
          'version': 1,
          'exportedAt': 'invalid-date',
          'lists': [],
        }),
        throwsA(isA<BackupFailure>()),
      );

      final withoutExportedAt = BackupData.fromJson({
        'version': 1,
        'lists': <dynamic>[],
      });
      expect(withoutExportedAt.version, 1);
      expect(withoutExportedAt.lists, isEmpty);

      final withGenericMap = BackupData.fromJson({
        'version': 1,
        'lists': [
          <dynamic, dynamic>{
            'id': 'l1',
            'name': 'Generic',
            'createdAt': DateTime(2026).toIso8601String(),
          },
        ],
      });
      expect(withGenericMap.lists.length, 1);
      expect(withGenericMap.lists.first.name, 'Generic');
    });
  });

  group('NativeFileService Tests', () {
    test('pickAndReadFile handles success, null, and exceptions', () async {
      final channel = const MethodChannel('test_file_system_open');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.arguments == 'throw_platform') {
              throw PlatformException(code: 'ERR', message: 'Pick failed');
            }
            if (call.arguments == 'throw_missing') {
              throw MissingPluginException();
            }
            if (call.arguments == 'null') {
              return null;
            }
            return {'name': 'backup.json', 'content': '{"version":1}'};
          });

      final service = NativeFileServiceImpl(channel: channel);

      final successResult = await service.pickAndReadFile();
      expect(successResult?['name'], 'backup.json');
      expect(successResult?['content'], '{"version":1}');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      final nullResult = await service.pickAndReadFile();
      expect(nullResult, isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => throw MissingPluginException(),
          );
      final missingResult = await service.pickAndReadFile();
      expect(missingResult, isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async =>
                throw PlatformException(code: 'ERR', message: 'Fail'),
          );
      final platformResult = await service.pickAndReadFile();
      expect(platformResult, isNull);
    });

    test('saveFile handles success, null, and exceptions', () async {
      final channel = const MethodChannel('test_file_system_save');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            return {'name': 'saved.json', 'uri': 'content://uri'};
          });

      final service = NativeFileServiceImpl(channel: channel);
      final successResult = await service.saveFile(
        fileName: 'saved.json',
        content: '{}',
      );
      expect(successResult?['name'], 'saved.json');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      final nullResult = await service.saveFile(
        fileName: 'saved.json',
        content: '{}',
      );
      expect(nullResult, isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => throw MissingPluginException(),
          );
      final missingResult = await service.saveFile(
        fileName: 'saved.json',
        content: '{}',
      );
      expect(missingResult, isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async =>
                throw PlatformException(code: 'ERR', message: 'Fail'),
          );
      final platformResult = await service.saveFile(
        fileName: 'saved.json',
        content: '{}',
      );
      expect(platformResult, isNull);
    });

    test('shareFile with custom launcher and default share_plus', () async {
      List<XFile>? passedFiles;
      String? passedSubject;

      final serviceWithLauncher = NativeFileServiceImpl(
        shareFilesLauncher: (files, {subject, text}) async {
          passedFiles = files;
          passedSubject = subject;
          return const ShareResult('ok', ShareResultStatus.success);
        },
      );

      await serviceWithLauncher.shareFile(
        fileName: 'test.json',
        content: '{"hello":"world"}',
        subject: 'My Subject',
      );

      expect(passedFiles, isNotNull);
      expect(passedFiles!.first.name, 'test.json');
      expect(passedSubject, 'My Subject');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            (MethodCall call) async {
              return 'android.intent.action.SEND';
            },
          );

      final serviceDefault = NativeFileServiceImpl();
      await serviceDefault.shareFile(fileName: 'default.json', content: 'data');
    });

    test('nativeFileServiceProvider provides instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(nativeFileServiceProvider);
      expect(service, isA<NativeFileService>());
    });
  });

  group('BackupLocalDataSource Tests', () {
    test('fetchAllLists and restoreLists with merge and replace', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (d, v) async {
          await d.execute('''
            CREATE TABLE lists (
              id TEXT PRIMARY KEY,
              name TEXT,
              is_synced INTEGER DEFAULT 0,
              is_starred INTEGER DEFAULT 0,
              is_shared INTEGER DEFAULT 0,
              has_invite INTEGER DEFAULT 0,
              position INTEGER DEFAULT 0,
              created_at INTEGER,
              updated_at INTEGER,
              deleted_at INTEGER
            );
          ''');
          await d.execute('''
            CREATE TABLE items (
              id TEXT PRIMARY KEY,
              list_id TEXT,
              title TEXT,
              is_completed INTEGER DEFAULT 0,
              is_synced INTEGER DEFAULT 0,
              position INTEGER DEFAULT 0,
              created_at INTEGER,
              updated_at INTEGER,
              deleted_at INTEGER
            );
          ''');
          await d.execute('''
            CREATE TABLE collaborators (
              id TEXT PRIMARY KEY,
              list_id TEXT,
              name TEXT,
              email TEXT,
              is_owner INTEGER DEFAULT 0,
              role TEXT DEFAULT 'member'
            );
          ''');
        },
      );

      await db.delete('lists');
      await db.delete('items');
      await db.delete('collaborators');

      final source = BackupLocalDataSourceImpl(db: Future.value(db));

      final empty = await source.fetchAllLists();
      expect(empty, isEmpty);

      final now = DateTime(2026, 10, 7);
      final list1 = ShoppingList(
        id: 'l1',
        name: 'List One',
        items: [
          TodoItem(
            id: 'i1',
            listId: 'l1',
            title: 'Item 1',
            isCompleted: false,
            createdAt: now,
          ),
        ],
        collaborators: const [
          Collaborator(
            id: 'c1',
            name: 'User',
            email: 'user@example.com',
            role: CollaboratorRole.owner,
          ),
        ],
        createdAt: now,
      );

      final restoreRes = await source.restoreLists([
        list1,
      ], replaceExisting: false);
      expect(restoreRes.success, isTrue);
      expect(restoreRes.listsRestored, 1);
      expect(restoreRes.itemsRestored, 1);

      await db.insert('collaborators', {
        'id': 'c_unknown',
        'list_id': 'l1',
        'name': 'Other',
        'email': 'other@example.com',
        'is_owner': 0,
        'role': 'unknown_role',
      });

      final loaded = await source.fetchAllLists();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'l1');
      expect(loaded.first.name, 'List One');
      expect(loaded.first.items.length, 1);
      expect(loaded.first.collaborators.length, 2);

      final list2 = ShoppingList(
        id: 'l2',
        name: 'List Two',
        items: [
          TodoItem(id: 'i2', listId: 'l2', title: 'Item 2', createdAt: now),
          TodoItem(id: 'i3', listId: 'l2', title: 'Item 3', createdAt: now),
        ],
        createdAt: now,
      );

      final replaceRes = await source.restoreLists([
        list2,
      ], replaceExisting: true);
      expect(replaceRes.success, isTrue);
      expect(replaceRes.listsRestored, 1);
      expect(replaceRes.itemsRestored, 2);

      final loadedReplaced = await source.fetchAllLists();
      expect(loadedReplaced.length, 1);
      expect(loadedReplaced.first.id, 'l2');
      expect(loadedReplaced.first.name, 'List Two');
      expect(loadedReplaced.first.items.length, 2);

      await db.close();

      expect(() => source.fetchAllLists(), throwsA(isA<BackupFailure>()));
      expect(
        () => source.restoreLists([list1], replaceExisting: false),
        throwsA(isA<BackupFailure>()),
      );
    });

    test('backupLocalDataSourceProvider provides instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ds = container.read(backupLocalDataSourceProvider);
      expect(ds, isA<BackupLocalDataSource>());
    });
  });

  group('BackupRepositoryImpl Tests', () {
    test('coordinate datasources, export, parse and restore', () async {
      final now = DateTime(2026, 10, 7);
      final list = ShoppingList(
        id: 'l1',
        name: 'Repo List',
        items: [
          TodoItem(id: 'i1', listId: 'l1', title: 'Repo Item', createdAt: now),
        ],
        createdAt: now,
      );

      final mockLocal = _MockLocalDataSource([list]);
      final mockNative = _MockNativeFileService();

      final repo = BackupRepositoryImpl(
        localDataSource: mockLocal,
        nativeFileService: mockNative,
      );

      final data = await repo.createBackupData();
      expect(data.totalLists, 1);
      expect(data.totalItems, 1);

      final jsonStr = await repo.exportBackupJson();
      expect(jsonStr, contains('Repo List'));

      final csvStr = await repo.exportBackupCsv();
      expect(csvStr, contains('Repo List'));
      expect(csvStr, contains('Repo Item'));

      final textStr = await repo.exportPlainTextSummary();
      expect(textStr, contains('Repo List'));

      final parsed = await repo.parseBackupJson(jsonStr);
      expect(parsed.totalLists, 1);

      expect(
        () => repo.parseBackupJson('not a json'),
        throwsA(isA<BackupFailure>()),
      );
      expect(
        () => repo.parseBackupJson('["array not map"]'),
        throwsA(isA<BackupFailure>()),
      );

      final restoreRes = await repo.restoreBackup(data, replaceExisting: true);
      expect(restoreRes.success, isTrue);

      final saveSuccess = await repo.saveBackupToFile(
        fileName: 'save.json',
        content: jsonStr,
      );
      expect(saveSuccess.success, isTrue);
      expect(saveSuccess.fileName, 'save.json');

      mockNative.saveResult = null;
      final saveCanceled = await repo.saveBackupToFile(
        fileName: 'save.json',
        content: jsonStr,
      );
      expect(saveCanceled.success, isFalse);

      mockNative.pickedFile = {'name': 'file.json', 'content': jsonStr};
      final picked = await repo.pickBackupFile();
      expect(picked?['name'], 'file.json');

      await repo.shareBackup(fileName: 'share.json', content: jsonStr);
      expect(mockNative.sharedFiles.length, 1);
    });

    test('backupRepositoryProvider provides instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(backupRepositoryProvider);
      expect(repo, isA<BackupRepository>());
    });
  });

  group('BackupController Unit Tests', () {
    test('build and refreshStats loads counts from repository', () async {
      final repo = FakeBackupRepository();
      final container = ProviderContainer(
        overrides: [backupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(backupControllerProvider.future);
      expect(initial.totalLists, 1);
      expect(initial.totalItems, 1);

      repo.internalData = repo.internalData.copyWith(
        lists: [
          repo.internalData.lists.first,
          ShoppingList(
            id: 'l2',
            name: 'List 2',
            items: const [],
            createdAt: DateTime.now(),
          ),
        ],
      );

      await container.read(backupControllerProvider.notifier).refreshStats();
      final updated = container.read(backupControllerProvider).value!;
      expect(updated.totalLists, 2);
    });

    test('exportAndSaveCsvFile success and error flows', () async {
      final repo = FakeBackupRepository();
      final container = ProviderContainer(
        overrides: [backupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(backupControllerProvider.future);

      final res = await container
          .read(backupControllerProvider.notifier)
          .exportAndSaveCsvFile();
      expect(res?.success, isTrue);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.success,
      );

      repo.shouldThrow = true;
      final errorRes = await container
          .read(backupControllerProvider.notifier)
          .exportAndSaveCsvFile();
      expect(errorRes, isNull);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.error,
      );
    });

    test('exportAndSaveJsonFile success and error flows', () async {
      final repo = FakeBackupRepository();
      final container = ProviderContainer(
        overrides: [backupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(backupControllerProvider.future);

      final res = await container
          .read(backupControllerProvider.notifier)
          .exportAndSaveJsonFile();
      expect(res?.success, isTrue);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.success,
      );

      repo.shouldThrow = true;
      final errorRes = await container
          .read(backupControllerProvider.notifier)
          .exportAndSaveJsonFile();
      expect(errorRes, isNull);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.error,
      );
    });

    test('exportAndShareJsonFile and exportAndSharePlainText', () async {
      final repo = FakeBackupRepository();
      final container = ProviderContainer(
        overrides: [backupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(backupControllerProvider.future);

      await container
          .read(backupControllerProvider.notifier)
          .exportAndShareJsonFile();
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.success,
      );

      await container
          .read(backupControllerProvider.notifier)
          .exportAndSharePlainText();
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.success,
      );

      repo.shouldThrow = true;
      await container
          .read(backupControllerProvider.notifier)
          .exportAndShareJsonFile();
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.error,
      );

      await container
          .read(backupControllerProvider.notifier)
          .exportAndSharePlainText();
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.error,
      );
    });

    test('pickBackupFile, clearPendingImport and confirmRestore', () async {
      final repo = FakeBackupRepository();
      final container = ProviderContainer(
        overrides: [backupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(backupControllerProvider.future);

      final canceled = await container
          .read(backupControllerProvider.notifier)
          .pickBackupFile();
      expect(canceled, isNull);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.initial,
      );

      repo.mockPickedFile = {
        'name': 'backup.json',
        'content': repo.internalData.toPrettyJson(),
      };
      final picked = await container
          .read(backupControllerProvider.notifier)
          .pickBackupFile();
      expect(picked, isNotNull);
      expect(
        container.read(backupControllerProvider).value?.pendingImportBackup,
        isNotNull,
      );

      container.read(backupControllerProvider.notifier).clearPendingImport();
      expect(
        container.read(backupControllerProvider).value?.pendingImportBackup,
        isNull,
      );

      final noPendingRestore = await container
          .read(backupControllerProvider.notifier)
          .confirmRestore(replaceExisting: false);
      expect(noPendingRestore, isNull);

      await container.read(backupControllerProvider.notifier).pickBackupFile();
      final restoreRes = await container
          .read(backupControllerProvider.notifier)
          .confirmRestore(replaceExisting: true);
      expect(restoreRes?.success, isTrue);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.success,
      );

      await container.read(backupControllerProvider.notifier).pickBackupFile();
      repo.shouldThrow = true;
      final restoreFail = await container
          .read(backupControllerProvider.notifier)
          .confirmRestore(replaceExisting: false);
      expect(restoreFail, isNull);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.error,
      );

      repo.mockPickedFile = {'name': 'bad.json', 'content': 'not-json'};
      repo.shouldThrow = false;
      final parseFail = await container
          .read(backupControllerProvider.notifier)
          .pickBackupFile();
      expect(parseFail, isNull);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.error,
      );
    });

    test('restoreFromJsonContent success and failure', () async {
      final repo = FakeBackupRepository();
      final container = ProviderContainer(
        overrides: [backupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(backupControllerProvider.future);

      final validJson = repo.internalData.toPrettyJson();
      final res = await container
          .read(backupControllerProvider.notifier)
          .restoreFromJsonContent(validJson, replaceExisting: false);
      expect(res?.success, isTrue);

      final err = await container
          .read(backupControllerProvider.notifier)
          .restoreFromJsonContent('invalid json', replaceExisting: false);
      expect(err, isNull);
      expect(
        container.read(backupControllerProvider).value?.status,
        BackupStatus.error,
      );
    });

    test('BackupState equality and copyWith', () {
      const state1 = BackupState(totalLists: 1, totalItems: 2);
      const state2 = BackupState(totalLists: 1, totalItems: 2);
      expect(state1, equals(state2));
      expect(state1.hashCode, state2.hashCode);

      final copied = state1.copyWith(
        status: BackupStatus.success,
        message: 'Saved',
        totalLists: 3,
        totalItems: 4,
      );
      expect(copied.status, BackupStatus.success);
      expect(copied.message, 'Saved');
      expect(copied.totalLists, 3);
      expect(copied.totalItems, 4);

      final cleared = copied.copyWith(clearMessage: true);
      expect(cleared.message, isNull);
    });
  });

  group('BackupScreen Widget Tests', () {
    testWidgets('renders all cards, handles back tap and export actions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeBackupRepository();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(path: '/backup', builder: (c, s) => const BackupScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [backupRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      router.push('/backup');
      await tester.pumpAndSettle();

      expect(find.byType(BackupScreen), findsOneWidget);
      expect(find.byKey(const Key('export_data_csv_tile')), findsOneWidget);
      expect(find.byKey(const Key('backup_data_json_tile')), findsOneWidget);
      expect(find.byKey(const Key('restore_json_tile')), findsOneWidget);

      await tester.tap(find.byKey(const Key('export_data_csv_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.tap(find.byKey(const Key('backup_data_json_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsWidgets);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('handles import dialog cancel, merge and replace', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeBackupRepository();
      repo.mockPickedFile = {
        'name': 'backup.json',
        'content': repo.internalData.toPrettyJson(),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [backupRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BackupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('restore_json_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(
        find.byKey(const Key('restore_dialog_merge_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('restore_dialog_replace_button')),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byKey(const Key('restore_json_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore_dialog_merge_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.tap(find.byKey(const Key('restore_json_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore_dialog_replace_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows error SnackBar when file pick parsing fails', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeBackupRepository();
      repo.mockPickedFile = {'name': 'invalid.json', 'content': 'not-a-json'};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [backupRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BackupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('restore_json_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('SettingsScreen Backup Tile and Navigation Tests', () {
    testWidgets('SettingsScreen displays backup tile and navigates to backup', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: AppRoutes.settings,
        routes: [
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.backup,
            builder: (context, state) => const BackupScreen(),
          ),
        ],
      );

      final repo = FakeBackupRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupRepositoryProvider.overrideWithValue(repo),
            notificationServiceProvider.overrideWithValue(
              _FakeNotificationService(),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_backup_and_export_tile')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('settings_backup_and_export_tile')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackupScreen), findsOneWidget);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
    });
  });

  group('AppStrings Backup Getters Coverage', () {
    test('verifies all backup localization getters', () {
      final stringsEs = AppStrings(AppLanguage.es);
      expect(stringsEs.backupAndExport, isNotEmpty);
      expect(stringsEs.backupAndExportSubtitle, isNotEmpty);
      expect(stringsEs.backupTitle, isNotEmpty);
      expect(stringsEs.exportData, isNotEmpty);
      expect(stringsEs.exportJsonBackup, isNotEmpty);
      expect(stringsEs.exportJsonBackupDesc, isNotEmpty);
      expect(stringsEs.importBackup, isNotEmpty);
      expect(stringsEs.importBackupDesc, isNotEmpty);
      expect(stringsEs.exportTextSummary, isNotEmpty);
      expect(stringsEs.exportTextSummaryDesc, isNotEmpty);
      expect(stringsEs.saveToDevice, isNotEmpty);
      expect(stringsEs.shareBackupFile, isNotEmpty);
      expect(stringsEs.openFromFileSystem, isNotEmpty);
      expect(stringsEs.backupSuccess, isNotEmpty);
      expect(stringsEs.restoreSuccess(2, 5), contains('2'));
      expect(stringsEs.restoreConfirmTitle, isNotEmpty);
      expect(stringsEs.restoreConfirmMessage(2, 5), contains('2'));
      expect(stringsEs.restoreMerge, isNotEmpty);
      expect(stringsEs.restoreReplace, isNotEmpty);
      expect(stringsEs.backupInvalidFile, isNotEmpty);
      expect(stringsEs.backupEmpty, isNotEmpty);
      expect(stringsEs.listsSummaryTitle, isNotEmpty);
      expect(stringsEs.totalListsCount(3), contains('3'));
      expect(stringsEs.totalItemsCount(7), contains('7'));
      expect(stringsEs.nativeFileSystemTitle, isNotEmpty);
      expect(stringsEs.nativeFileSystemDesc, isNotEmpty);
      expect(stringsEs.exportDataCsv, isNotEmpty);
      expect(stringsEs.exportDataCsvDesc, isNotEmpty);
      expect(stringsEs.backupDataJson, isNotEmpty);
      expect(stringsEs.backupDataJsonDesc, isNotEmpty);
      expect(stringsEs.restoreJson, isNotEmpty);
      expect(stringsEs.restoreJsonDesc, isNotEmpty);
      expect(stringsEs.csvExportSuccess, isNotEmpty);

      final stringsEn = AppStrings(AppLanguage.en);
      expect(stringsEn.backupAndExport, 'Backup & Export Data');
      expect(stringsEn.backupAndExportSubtitle, isNotEmpty);
      expect(stringsEn.backupTitle, isNotEmpty);
      expect(stringsEn.exportData, isNotEmpty);
      expect(stringsEn.exportJsonBackup, isNotEmpty);
      expect(stringsEn.exportJsonBackupDesc, isNotEmpty);
      expect(stringsEn.importBackup, isNotEmpty);
      expect(stringsEn.importBackupDesc, isNotEmpty);
      expect(stringsEn.exportTextSummary, isNotEmpty);
      expect(stringsEn.exportTextSummaryDesc, isNotEmpty);
      expect(stringsEn.saveToDevice, isNotEmpty);
      expect(stringsEn.shareBackupFile, isNotEmpty);
      expect(stringsEn.openFromFileSystem, isNotEmpty);
      expect(stringsEn.backupSuccess, isNotEmpty);
      expect(stringsEn.restoreSuccess(1, 2), 'Restored 1 lists and 2 items');
      expect(stringsEn.restoreConfirmTitle, isNotEmpty);
      expect(
        stringsEn.restoreConfirmMessage(1, 2),
        'The file contains 1 lists and 2 items. How would you like to restore?',
      );
      expect(stringsEn.restoreMerge, isNotEmpty);
      expect(stringsEn.restoreReplace, isNotEmpty);
      expect(stringsEn.backupInvalidFile, isNotEmpty);
      expect(stringsEn.backupEmpty, isNotEmpty);
      expect(stringsEn.listsSummaryTitle, isNotEmpty);
      expect(stringsEn.totalListsCount(5), '5 lists');
      expect(stringsEn.totalItemsCount(10), '10 items');
      expect(stringsEn.nativeFileSystemTitle, isNotEmpty);
      expect(stringsEn.nativeFileSystemDesc, isNotEmpty);
      expect(stringsEn.exportDataCsv, 'Export data CSV');
      expect(stringsEn.exportDataCsvDesc, isNotEmpty);
      expect(stringsEn.backupDataJson, 'Backup data JSON');
      expect(stringsEn.backupDataJsonDesc, isNotEmpty);
      expect(stringsEn.restoreJson, 'Restore JSON');
      expect(stringsEn.restoreJsonDesc, isNotEmpty);
      expect(stringsEn.csvExportSuccess, isNotEmpty);
    });
  });
}

class _MockLocalDataSource implements BackupLocalDataSource {
  final List<ShoppingList> lists;

  _MockLocalDataSource(this.lists);

  @override
  Future<List<ShoppingList>> fetchAllLists() async => List.from(lists);

  @override
  Future<BackupImportResult> restoreLists(
    List<ShoppingList> newLists, {
    required bool replaceExisting,
  }) async {
    return BackupImportResult(
      success: true,
      listsRestored: newLists.length,
      itemsRestored: newLists.fold(0, (s, l) => s + l.items.length),
    );
  }
}

class _MockNativeFileService implements NativeFileService {
  Map<String, dynamic>? saveResult = {'name': 'save.json', 'uri': '/save.json'};
  Map<String, dynamic>? pickedFile;
  final List<String> sharedFiles = [];

  @override
  Future<Map<String, dynamic>?> pickAndReadFile() async => pickedFile;

  @override
  Future<Map<String, dynamic>?> saveFile({
    required String fileName,
    required String content,
    String? mimeType,
  }) async => saveResult;

  @override
  Future<void> shareFile({
    required String fileName,
    required String content,
    String? mimeType,
    String? subject,
  }) async {
    sharedFiles.add(fileName);
  }
}
