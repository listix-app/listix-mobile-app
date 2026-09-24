import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/create_edit_list_screen.dart';
import 'package:listix/src/features/lists/presentation/screens/home_screen.dart';
import 'package:listix/src/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_card.dart';
import 'package:listix/src/routing/app_router.dart';
import 'package:listix/src/routing/routes.dart';

void main() {
  final now = DateTime(2026, 9, 22);

  group('CreateEditListScreen widget tests', () {
    testWidgets('create list mode validates input and creates list', (
      tester,
    ) async {
      final fakeController = _ScreensTestListsController([]);

      final router = GoRouter(
        initialLocation: '/lists/new',
        routes: [
          GoRoute(
            path: '/lists/new',
            builder: (context, state) => const CreateEditListScreen(),
          ),
          GoRoute(
            path: '/list/:id',
            builder: (context, state) =>
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

      expect(find.text('Crear lista'), findsOneWidget);
      expect(find.text('Nueva lista'), findsOneWidget);
      await tester.tap(find.text('Crear lista'));
      await tester.pump();
      expect(find.text('Por favor ingresa un nombre'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Nueva Despensa');
      await tester.tap(find.text('Crear lista'));
      await tester.pumpAndSettle();

      expect(fakeController.createdNames, contains('Nueva Despensa'));
      expect(find.text('List: created_new'), findsOneWidget);
    });

    testWidgets('edit list mode populates name and saves changes', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'edit_target',
        name: 'Lista Vieja',
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
                onPressed: () => ctx.push('/list/edit_target/edit'),
                child: const Text('Go Edit'),
              ),
            ),
          ),
          GoRoute(
            path: '/list/:id/edit',
            builder: (context, state) =>
                CreateEditListScreen(listId: state.pathParameters['id']),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListProvider('edit_target').overrideWithValue(list),
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.text('Go Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Lista Vieja'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Lista Actualizada');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(fakeController.updatedNames['edit_target'], 'Lista Actualizada');
      expect(find.text('Go Edit'), findsOneWidget);
    });

    testWidgets('tap back button on CreateEditListScreen', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ctx.push('/lists/new'),
                child: const Text('Go New'),
              ),
            ),
          ),
          GoRoute(
            path: '/lists/new',
            builder: (ctx, state) => const CreateEditListScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.tap(find.text('Go New'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateEditListScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Go New'), findsOneWidget);
    });
  });

  group('HomeScreen widget tests', () {
    testWidgets(
      'renders empty state when lists are empty and navigates to new list',
      (tester) async {
        final fakeController = _ScreensTestListsController([]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
            GoRoute(
              path: '/lists/new',
              builder: (ctx, state) => const Text('New List Screen'),
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

        await tester.pumpAndSettle();

        expect(find.text('Tus listas, siempre contigo'), findsOneWidget);
        await tester.tap(find.text('Crear mi primera lista'));
        await tester.pumpAndSettle();

        expect(find.text('New List Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'renders lists, handles pull-to-refresh and dismissal dialog cancel/confirm',
      (tester) async {
        final list = ShoppingList(
          id: 'l1',
          name: 'Supermercado',
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([list]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
            GoRoute(
              path: '/settings',
              builder: (ctx, state) => const Text('Settings Screen Target'),
            ),
            GoRoute(
              path: '/list/:id',
              builder: (ctx, state) =>
                  Text('Detail: ${state.pathParameters['id']}'),
            ),
            GoRoute(
              path: '/lists/new',
              builder: (ctx, state) => const Text('New Target'),
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

        await tester.pumpAndSettle();

        expect(find.text('Supermercado'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();
        expect(fakeController.manualSyncCalled, isTrue);

        await tester.tap(find.byType(ListCard));
        await tester.pumpAndSettle();
        expect(find.text('Detail: l1'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
        await tester.pumpAndSettle();
        expect(fakeController.starredListIds, contains('l1'));

        final reorderableHomeScreen = tester.widget<ReorderableListView>(
          find.byType(ReorderableListView),
        );
        reorderableHomeScreen.onReorderItem!(0, 1);
        await tester.pumpAndSettle();
        expect(fakeController.reorderedListsCalled, isTrue);

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar lista?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(fakeController.deletedListIds, isEmpty);

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar lista?'), findsOneWidget);
        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();
        expect(fakeController.deletedListIds, contains('l1'));

        expect(find.text('Deshacer'), findsOneWidget);
        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();
        expect(fakeController.restoredLists.length, 1);

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Settings Screen Target'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.text('New Target'), findsOneWidget);
      },
    );
  });

  group('ListDetailScreen widget tests', () {
    testWidgets('renders list not found when list is null and pops back', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/list/unknown_list',
        routes: [
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

      await tester.pumpAndSettle();

      expect(find.text('Lista no encontrada'), findsOneWidget);
    });

    testWidgets('renders detail with items, toggles expansion, and adds item', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'detail_1',
        name: 'Mercado Mensual',
        items: [
          TodoItem(
            id: 'i1',
            listId: 'detail_1',
            title: 'Queso',
            isCompleted: false,
            createdAt: now,
          ),
          TodoItem(
            id: 'i2',
            listId: 'detail_1',
            title: 'Vino',
            isCompleted: true,
            createdAt: now,
          ),
        ],
        collaborators: const [
          Collaborator(id: 'c1', name: 'Ana', email: 'ana@test.com'),
        ],
        createdAt: now,
      );
      final fakeController = _ScreensTestListsController([list]);

      final router = GoRouter(
        initialLocation: '/list/detail_1',
        routes: [
          GoRoute(
            path: '/list/:id',
            builder: (ctx, state) =>
                ListDetailScreen(listId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/list/:id/edit',
            builder: (ctx, state) =>
                Text('Edit: ${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListProvider('detail_1').overrideWithValue(list),
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mercado Mensual'), findsOneWidget);
      expect(find.text('1 de 2 pendientes'), findsOneWidget);
      expect(find.text('50% completado'), findsOneWidget);
      expect(find.text('Completados (1)'), findsOneWidget);

      await tester.tap(find.text('Queso'));
      await tester.pump();
      expect(fakeController.toggledItemIds, contains('i1'));

      await tester.tap(find.text('Completados (1)'));
      await tester.pump();
      expect(find.text('Vino'), findsNothing);

      await tester.tap(find.text('Completados (1)'));
      await tester.pump();
      expect(find.text('Vino'), findsOneWidget);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(fakeController.manualSyncCalled, isTrue);

      await tester.enterText(find.byType(TextField), 'Mantequilla');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(fakeController.addedItems, contains('Mantequilla'));

      final reorderableDetail = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderableDetail.onReorderItem!(0, 1);
      await tester.pumpAndSettle();
      expect(fakeController.reorderedItemsCalled, isTrue);

      await tester.tap(find.byTooltip('Renombrar'));
      await tester.pumpAndSettle();
      expect(find.text('Edit: detail_1'), findsOneWidget);
    });

    testWidgets('renders empty items state and opens share modal', (
      tester,
    ) async {
      final emptyList = ShoppingList(
        id: 'empty_list',
        name: 'Lista Sin Cosas',
        items: const [],
        createdAt: now,
      );

      final router = GoRouter(
        initialLocation: '/list/empty_list',
        routes: [
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
            shoppingListProvider('empty_list').overrideWithValue(emptyList),
            listsControllerProvider.overrideWith(
              () => _ScreensTestListsController([emptyList]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sin items aún'), findsOneWidget);

      await tester.tap(find.byTooltip('Compartir lista'));
      await tester.pumpAndSettle();

      expect(find.text('Compartir "Lista Sin Cosas"'), findsOneWidget);
    });
  });

  group('App Router integration tests', () {
    testWidgets('can navigate across all defined routes in AppRoutes', (
      tester,
    ) async {
      final emptyController = _ScreensTestListsController([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => emptyController),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      container.read(appRouterProvider).go(AppRoutes.newList);
      await tester.pumpAndSettle();
      expect(find.byType(CreateEditListScreen), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.listDetailPath('1'));
      await tester.pumpAndSettle();
      expect(find.byType(ListDetailScreen), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.editListPath('1'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateEditListScreen), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.about);
      await tester.pumpAndSettle();
      expect(find.text('Listix'), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();
      expect(find.text('Configuración'), findsWidgets);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    });
  });
}

class _ScreensTestListsController extends ListsController {
  final List<ShoppingList> _lists;
  final List<String> createdNames = [];
  final Map<String, String> updatedNames = {};
  final List<String> deletedListIds = [];
  final List<ShoppingList> restoredLists = [];
  final List<String> starredListIds = [];
  final List<String> addedItems = [];
  final List<String> toggledItemIds = [];
  final List<String> deletedItemIds = [];
  final List<TodoItem> restoredItems = [];
  bool manualSyncCalled = false;
  bool reorderedListsCalled = false;
  bool reorderedItemsCalled = false;

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
  Future<void> updateListName(String listId, String newName) async {
    updatedNames[listId] = newName;
  }

  @override
  Future<void> deleteList(String listId) async {
    deletedListIds.add(listId);
  }

  @override
  Future<ShoppingList?> deleteListWithUndo(String listId) async {
    deletedListIds.add(listId);
    return _lists.where((l) => l.id == listId).firstOrNull;
  }

  @override
  Future<void> restoreList(ShoppingList list) async {
    restoredLists.add(list);
  }

  @override
  Future<void> toggleStar(String listId) async {
    starredListIds.add(listId);
  }

  @override
  Future<void> reorderLists(int oldIndex, int newIndex) async {
    reorderedListsCalled = true;
  }

  @override
  Future<void> addItem(String listId, String title) async {
    addedItems.add(title);
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
  Future<void> reorderItems(String listId, int oldIndex, int newIndex) async {
    reorderedItemsCalled = true;
  }

  @override
  Future<void> manualSync() async {
    manualSyncCalled = true;
  }
}
