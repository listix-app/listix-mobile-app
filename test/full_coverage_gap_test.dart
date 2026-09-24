import 'package:listix/src/features/lists/presentation/widgets/todo_item_tile.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/core/localization/locale_controller.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/core/widgets/listix_logo.dart';
import 'package:listix/src/features/about/presentation/screens/about_screen.dart';
import 'package:listix/src/features/ads/data/ad_config.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/create_edit_list_screen.dart';
import 'package:listix/src/features/lists/presentation/screens/home_screen.dart';
import 'package:listix/src/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:listix/src/features/sync/data/mock_backend_sync_service.dart';
import 'package:listix/src/features/sync/domain/sync_status.dart';
import 'package:listix/src/features/sync/presentation/sync_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 22);

  setUpAll(() {
    sqfliteFfiInit();
    try {
      if (databaseFactory != databaseFactoryFfi) {
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {
      databaseFactory = databaseFactoryFfi;
    }
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
  });

  group('Coverage Gaps - Localization and Strings', () {
    test('Exercise all AppStrings getters in Spanish and English', () {
      for (final lang in [AppLanguage.es, AppLanguage.en]) {
        final tr = AppStrings(lang);
        expect(tr.isSpanish, lang == AppLanguage.es);
        expect(tr.appName, 'Listix');
        expect(tr.appTagline, isNotEmpty);
        expect(tr.myLists, isNotEmpty);
        expect(tr.emptyListsTitle, isNotEmpty);
        expect(tr.emptyListsMessage, isNotEmpty);
        expect(tr.createFirstList, isNotEmpty);
        expect(tr.newList, isNotEmpty);
        expect(tr.deleteListTitle, isNotEmpty);
        expect(tr.deleteListMessage('Test'), contains('Test'));
        expect(tr.cancel, isNotEmpty);
        expect(tr.delete, isNotEmpty);
        expect(tr.listCountSuffix, isNotEmpty);
        expect(tr.rename, isNotEmpty);
        expect(tr.shareList, isNotEmpty);
        expect(tr.noItemsYet, isNotEmpty);
        expect(tr.pendingCountText(1, 3), isNotEmpty);
        expect(tr.percentCompleted(50), contains('50'));
        expect(tr.completedGroup(2), contains('2'));
        expect(tr.emptyItemsTitle, isNotEmpty);
        expect(tr.emptyItemsMessage, isNotEmpty);
        expect(tr.quickAddHint, isNotEmpty);
        expect(tr.quickAddTooltip, isNotEmpty);
        expect(tr.back, isNotEmpty);
        expect(tr.listNotFound, isNotEmpty);
        expect(tr.renameListTitle, isNotEmpty);
        expect(tr.newListTitle, isNotEmpty);
        expect(tr.createListHeading, isNotEmpty);
        expect(tr.editListHeading, isNotEmpty);
        expect(tr.createListSubheading, isNotEmpty);
        expect(tr.editListSubheading, isNotEmpty);
        expect(tr.listNameLabel, isNotEmpty);
        expect(tr.listNameHint, isNotEmpty);
        expect(tr.listNameValidation, isNotEmpty);
        expect(tr.createListAction, isNotEmpty);
        expect(tr.saveChanges, isNotEmpty);
        expect(tr.shareHeading, isNotEmpty);
        expect(tr.shareListSubheading, isNotEmpty);
        expect(tr.copyInviteLink, isNotEmpty);
        expect(tr.linkCopied, isNotEmpty);
        expect(tr.inviteByEmail, isNotEmpty);
        expect(tr.emailHint, isNotEmpty);
        expect(tr.inviteAction, isNotEmpty);
        expect(tr.enterEmailError, isNotEmpty);
        expect(tr.invalidEmailError, isNotEmpty);
        expect(tr.collaboratorsHeading, isNotEmpty);
        expect(tr.noCollaboratorsYet, isNotEmpty);
        expect(tr.removeCollaborator, isNotEmpty);
        expect(tr.syncStatusTitle, isNotEmpty);
        expect(tr.syncStatusDescription, isNotEmpty);
        expect(tr.simulateOffline, isNotEmpty);
        expect(tr.simulateOfflineSubtitle, isNotEmpty);
        expect(tr.close, isNotEmpty);
        expect(tr.syncNow, isNotEmpty);
        expect(tr.statusSyncing, isNotEmpty);
        expect(tr.statusOffline, isNotEmpty);
        expect(tr.statusPending, isNotEmpty);
        expect(tr.statusSynced, isNotEmpty);
        expect(tr.aboutApp, isNotEmpty);
        expect(tr.version, isNotEmpty);
        expect(tr.languageTitle, isNotEmpty);
        expect(tr.privacyPolicy, isNotEmpty);
        expect(tr.termsOfService, isNotEmpty);
        expect(tr.privacyStatement, isNotEmpty);
        expect(tr.offlineFirstStatement, isNotEmpty);
        expect(tr.termsStatement, isNotEmpty);
        expect(tr.themeTitle, isNotEmpty);
        expect(tr.themeSystem, isNotEmpty);
        expect(tr.themeLight, isNotEmpty);
        expect(tr.themeDark, isNotEmpty);
        expect(tr.shareWhatsApp, isNotEmpty);
        expect(tr.shareGmail, isNotEmpty);
        expect(tr.copyListText, isNotEmpty);
        expect(tr.listCopied, isNotEmpty);
        expect(tr.shareSubject('Test'), contains('Test'));
        expect(tr.sharedWithListix, isNotEmpty);
        expect(tr.offlineNoticeDesc, isNotEmpty);
        expect(tr.shareWhatsAppDesc, isNotEmpty);
        expect(tr.shareGmailDesc, isNotEmpty);
        expect(tr.copyListTextDesc, isNotEmpty);
        expect(tr.offlineNotice, isNotEmpty);
        expect(tr.notificationsTitle, isNotEmpty);
        expect(tr.weeklyReminderTitle, isNotEmpty);
        expect(tr.weeklyReminderSubtitle, isNotEmpty);
        expect(tr.weeklyReminderNotificationTitle, isNotEmpty);
        expect(tr.weeklyReminderNotificationBody, isNotEmpty);
        expect(tr.undo, isNotEmpty);
        expect(tr.listDeleted('Test'), contains('Test'));
        expect(tr.itemDeleted('Test'), contains('Test'));
        expect(tr.starred, isNotEmpty);
        expect(tr.starList, isNotEmpty);
        expect(tr.unstarList, isNotEmpty);
        expect(tr.reorder, isNotEmpty);
        expect(tr.developer, isNotEmpty);
        expect(tr.developerName, isNotEmpty);
        expect(tr.developerEmail, isNotEmpty);
        expect(tr.contactDeveloper, isNotEmpty);
        expect(tr.buyMeACoffee, isNotEmpty);
        expect(tr.buyMeACoffeeSubtitle, isNotEmpty);
        expect(tr.sendFeedback, isNotEmpty);
        expect(tr.sendFeedbackSubtitle, isNotEmpty);
        expect(tr.rateApp, isNotEmpty);
        expect(tr.rateAppSubtitle, isNotEmpty);
        expect(tr.layoutTitle, isNotEmpty);
        expect(tr.layoutList, isNotEmpty);
        expect(tr.layoutGrid, isNotEmpty);
        expect(tr.switchLayout, isNotEmpty);
        expect(tr.adPolicyTitle, isNotEmpty);
        expect(tr.adPolicyStatement, isNotEmpty);
      }
    });

    test('LocaleController toggleLanguage and Provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(localeControllerProvider.notifier);
      expect(controller.state, const Locale('es'));

      controller.toggleLanguage();
      expect(controller.state, const Locale('en'));

      controller.toggleLanguage();
      expect(controller.state, const Locale('es'));

      controller.setLanguage(AppLanguage.en);
      expect(controller.state, const Locale('en'));
    });
  });

  group('Coverage Gaps - Entities & Database', () {
    test('Collaborator equality and hashCode with all field variants', () {
      const c1 = Collaborator(
        id: 'c1',
        name: 'Ana',
        email: 'ana@test.com',
        isOwner: true,
      );
      const c2 = Collaborator(
        id: 'c1',
        name: 'Ana',
        email: 'ana@test.com',
        isOwner: true,
      );
      const cDiffId = Collaborator(
        id: 'c2',
        name: 'Ana',
        email: 'ana@test.com',
        isOwner: true,
      );
      const cDiffName = Collaborator(
        id: 'c1',
        name: 'Bob',
        email: 'ana@test.com',
        isOwner: true,
      );
      const cDiffEmail = Collaborator(
        id: 'c1',
        name: 'Ana',
        email: 'bob@test.com',
        isOwner: true,
      );
      const cDiffOwner = Collaborator(
        id: 'c1',
        name: 'Ana',
        email: 'ana@test.com',
        isOwner: false,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1 == cDiffId, isFalse);
      expect(c1 == cDiffName, isFalse);
      expect(c1 == cDiffEmail, isFalse);
      expect(c1 == cDiffOwner, isFalse);
      expect(c1 == c1, isTrue);
    });

    test('AppDatabase path resolution and operations', () async {
      final db = await AppDatabase.instance.database;
      expect(db.isOpen, isTrue);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='shopping_lists'",
      );
      expect(tables.isNotEmpty, isTrue);

      final overridePath = await AppDatabase.resolveDatabasePath(
        override: '/custom/path.db',
      );
      expect(overridePath, '/custom/path.db');

      final desktopPath = await AppDatabase.resolveDatabasePath(
        isDesktop: true,
        getDocDir: () async => '/mock/desktop',
      );
      expect(desktopPath, contains('mock/desktop'));

      final mobilePath = await AppDatabase.resolveDatabasePath(
        isDesktop: false,
        getDefaultDatabasesPath: () async => '/mock/mobile',
      );
      expect(mobilePath, contains('mock/mobile'));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async => '/mock/app_support',
          );
      final p1 = await AppDatabase.resolveDatabasePath(isDesktop: true);
      expect(p1, contains('listix.db'));

      final p2 = await AppDatabase.resolveDatabasePath(isDesktop: false);
      expect(p2, contains('listix.db'));
    });

    testWidgets('CustomPainter shouldRepaint on ListixLogo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ListixLogo(size: 60))),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(ListixLogo),
        matching: find.byType(CustomPaint),
      );
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder);
      expect(
        customPaintWidget.painter!.shouldRepaint(customPaintWidget.painter!),
        isFalse,
      );
    });
  });

  group('Coverage Gaps - AdConfig', () {
    test('AdConfig provides valid IDs', () {
      expect(AdConfig.androidAppId, isNotEmpty);
      expect(AdConfig.iosAppId, isNotEmpty);
      expect(AdConfig.bannerId, isNotEmpty);
    });
  });

  group('Coverage Gaps - Screens and Widgets Interactions', () {
    testWidgets('AboutScreen back button pops router', (tester) async {
      final router = GoRouter(
        initialLocation: '/prev',
        routes: [
          GoRoute(
            path: '/prev',
            builder: (ctx, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ctx.push('/about'),
                child: const Text('Go About'),
              ),
            ),
          ),
          GoRoute(path: '/about', builder: (ctx, state) => const AboutScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.tap(find.text('Go About'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Go About'), findsOneWidget);
    });

    testWidgets('CreateEditListScreen onFieldSubmitted trigger', (
      tester,
    ) async {
      final fakeController = _ScreensTestListsController([]);

      final router = GoRouter(
        initialLocation: '/lists/new',
        routes: [
          GoRoute(
            path: '/lists/new',
            builder: (ctx, state) => const CreateEditListScreen(),
          ),
          GoRoute(
            path: '/list/:id',
            builder: (ctx, state) =>
                Text('List: ${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Enter List');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(fakeController.createdNames, contains('Enter List'));
      expect(find.text('List: created_new'), findsOneWidget);
    });

    testWidgets('HomeScreen renders loading state', (tester) async {
      final completer = Completer<List<ShoppingList>>();
      final container = ProviderContainer(
        overrides: [
          listsControllerProvider.overrideWith(
            () => _LoadingListsController(completer),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete([]);
      await tester.pump();
    });

    testWidgets('HomeScreen renders error state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => _ErrorListsController()),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Simulated Failure'), findsOneWidget);
    });

    testWidgets(
      'ListDetailScreen pending/completed toggle, delete, and back buttons',
      (tester) async {
        final list = ShoppingList(
          id: 'detail_coverage',
          name: 'Detalle Completo',
          items: [
            TodoItem(
              id: 'i1',
              listId: 'detail_coverage',
              title: 'Pending Item',
              isCompleted: false,
              createdAt: now,
            ),
            TodoItem(
              id: 'i2',
              listId: 'detail_coverage',
              title: 'Done Item',
              isCompleted: true,
              createdAt: now,
            ),
          ],
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([list]);

        final router = GoRouter(
          initialLocation: '/prev',
          routes: [
            GoRoute(
              path: '/prev',
              builder: (ctx, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ctx.push('/list/detail_coverage'),
                  child: const Text('Go Detail'),
                ),
              ),
            ),
            GoRoute(
              path: '/list/:id',
              builder: (ctx, state) =>
                  ListDetailScreen(listId: state.pathParameters['id']!),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListProvider('detail_coverage').overrideWithValue(list),
              listsControllerProvider.overrideWith(() => fakeController),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.tap(find.text('Go Detail'));
        await tester.pumpAndSettle();

        await tester.drag(
          find.widgetWithText(Dismissible, 'Pending Item'),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        expect(fakeController.deletedItemIds, contains('i1'));
        expect(find.text('Deshacer'), findsOneWidget);
        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();
        expect(fakeController.restoredItems.length, 1);

        await tester.tap(find.text('Done Item'));
        await tester.pump();
        expect(fakeController.toggledItemIds, contains('i2'));

        await tester.drag(
          find.widgetWithText(Dismissible, 'Done Item'),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();
        expect(fakeController.deletedItemIds, contains('i2'));

        await tester.tap(find.byTooltip('Volver'));
        await tester.pumpAndSettle();
        expect(find.text('Go Detail'), findsOneWidget);
      },
    );

    testWidgets(
      'ListDetailScreen not found leading back button and filled button pop router',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/prev',
          routes: [
            GoRoute(
              path: '/prev',
              builder: (ctx, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => ctx.push('/list/missing'),
                  child: const Text('Go Missing'),
                ),
              ),
            ),
            GoRoute(
              path: '/list/:id',
              builder: (ctx, state) =>
                  ListDetailScreen(listId: state.pathParameters['id']!),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              listsControllerProvider.overrideWith(
                () => _ScreensTestListsController([]),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.tap(find.text('Go Missing'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Go Missing'), findsOneWidget);

        await tester.tap(find.text('Go Missing'));
        await tester.pumpAndSettle();
        expect(find.text('Lista no encontrada'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Volver'));
        await tester.pumpAndSettle();
        expect(find.text('Go Missing'), findsOneWidget);
      },
    );

    testWidgets('AboutScreen and TodoItemTile dark mode coverage', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AboutScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      await tester.scrollUntilVisible(find.byIcon(Icons.dark_mode_rounded), 200);
      await tester.tap(find.byIcon(Icons.dark_mode_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.light_mode_rounded));
      await tester.pumpAndSettle();

      final item = TodoItem(
        id: 'dark_item',
        listId: 'l1',
        title: 'Dark Mode Item',
        isCompleted: false,
        createdAt: now,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TodoItemTile(item: item, onToggle: () {}, onDelete: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dark Mode Item'), findsOneWidget);
    });
  });

  group(
    'Coverage Gaps - MockBackendSyncService offline branch and sync controller dispose',
    () {
      test(
        'synchronize offline simulation returns false and handles mid-sync offline',
        () async {
          final service = MockBackendSyncService();
          service.toggleSimulatedOffline();
          expect(service.isSimulatedOffline, isTrue);
          final result = await service.synchronize();
          expect(result, isFalse);
          expect(service.currentStatus, SyncStatus.offline);

          service.toggleSimulatedOffline();
          expect(service.isSimulatedOffline, isFalse);

          final db = await AppDatabase.instance.database;
          await db.insert('todo_items', {
            'id': 'unsynced_gap_item',
            'list_id': 'list-1',
            'title': 'Unsynced Gap Test',
            'is_completed': 0,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'is_synced': 0,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          final syncTask = service.synchronize();
          service.toggleSimulatedOffline();
          final midSyncResult = await syncTask;
          expect(midSyncResult, isFalse);
          expect(service.currentStatus, SyncStatus.offline);

          service.dispose();
        },
      );

      test(
        'SyncController subscription updates state and cancels onDispose',
        () async {
          final container = ProviderContainer();
          final sub = container.listen(syncControllerProvider, (_, _) {});
          final service = container.read(mockBackendSyncServiceProvider);

          service.toggleSimulatedOffline();
          await Future<void>.delayed(Duration.zero);
          expect(container.read(syncControllerProvider), SyncStatus.offline);

          sub.close();
          container.dispose();
        },
      );
    },
  );
}

class _ScreensTestListsController extends ListsController {
  final List<ShoppingList> _lists;
  final List<String> createdNames = [];
  final List<String> deletedItemIds = [];
  final List<String> toggledItemIds = [];
  final List<String> collaboratorsAdded = [];
  final List<String> syncedListIds = [];
  final List<TodoItem> restoredItems = [];

  _ScreensTestListsController(this._lists);

  @override
  Future<List<ShoppingList>> build() async => _lists;

  @override
  Future<ShoppingList> createList(String name) async {
    createdNames.add(name);
    return ShoppingList(
      id: 'created_new',
      name: name,
      createdAt: DateTime(2026, 9, 22),
    );
  }

  @override
  Future<void> toggleItem(String listId, String itemId) async {
    toggledItemIds.add(itemId);
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {
    deletedItemIds.add(itemId);
  }

  @override
  Future<TodoItem?> deleteItemWithUndo(String listId, String itemId) async {
    deletedItemIds.add(itemId);
    final list = _lists.where((l) => l.id == listId).firstOrNull;
    return list?.items.where((i) => i.id == itemId).firstOrNull;
  }

  @override
  Future<void> restoreItem(TodoItem item) async {
    restoredItems.add(item);
  }

  @override
  Future<void> addCollaborator(String listId, String email) async {
    collaboratorsAdded.add(email);
  }

  @override
  Future<void> syncListOnShare(String listId) async {
    syncedListIds.add(listId);
  }
}

class _LoadingListsController extends ListsController {
  final Completer<List<ShoppingList>> completer;
  _LoadingListsController([Completer<List<ShoppingList>>? completer])
    : completer = completer ?? Completer<List<ShoppingList>>();

  @override
  Future<List<ShoppingList>> build() => completer.future;
}

class _ErrorListsController extends ListsController {
  @override
  Future<List<ShoppingList>> build() async {
    Future.microtask(() {
      state = AsyncError<List<ShoppingList>>(
        Exception('Simulated Failure'),
        StackTrace.current,
      );
    });
    return Completer<List<ShoppingList>>().future;
  }
}
