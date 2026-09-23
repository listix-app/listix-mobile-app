import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:listix/src/features/ads/data/repositories/mock_admob_service.dart';
import 'package:listix/src/features/ads/presentation/controllers/admob_controller.dart';
import 'package:listix/src/features/ads/presentation/widgets/admob_interstitial_dialog.dart';
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
    testWidgets(
      'create list mode validates input and creates list with interstitial',
      (tester) async {
        final mockAdmob = MockAdmobService(simulatedLatency: Duration.zero);
        await mockAdmob.initialize();
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
              admobServiceProvider.overrideWithValue(mockAdmob),
              listsControllerProvider.overrideWith(() => fakeController),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        // Verify create title and submit empty to see validation error
        expect(find.text('Crear lista'), findsOneWidget); // Button text
        expect(find.text('Nueva lista'), findsOneWidget); // AppBar text
        await tester.tap(find.text('Crear lista'));
        await tester.pump();
        expect(find.text('Por favor ingresa un nombre'), findsOneWidget);

        // Enter name and submit
        await tester.enterText(find.byType(TextFormField), 'Nueva Despensa');
        await tester.tap(find.text('Crear lista'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AdmobInterstitialDialog), findsOneWidget);

        // Interact with interstitial CTA button to complete ad interaction
        await tester.tap(
          find.descendant(
            of: find.byType(AdmobInterstitialDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(fakeController.createdNames, contains('Nueva Despensa'));
        expect(find.text('List: created_new'), findsOneWidget);

        mockAdmob.dispose();
      },
    );

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

      // Verify name is pre-populated
      expect(find.text('Lista Vieja'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);

      // Change name and submit
      await tester.enterText(find.byType(TextFormField), 'Lista Actualizada');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(fakeController.updatedNames['edit_target'], 'Lista Actualizada');
      expect(find.text('Go Edit'), findsOneWidget); // Popped back to prev
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

        expect(find.text('Aún no tienes listas'), findsOneWidget);
        await tester.tap(find.text('Crea tu primera lista'));
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
              path: '/about',
              builder: (ctx, state) => const Text('About Screen Target'),
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
        expect(find.text('1'), findsOneWidget); // count badge

        // Pull to refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();
        expect(fakeController.manualSyncCalled, isTrue);

        // Tap card navigates to /list/l1
        await tester.tap(find.byType(ListCard));
        await tester.pumpAndSettle();
        expect(find.text('Detail: l1'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();

        // Dismiss swipe and Cancel
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar lista?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(fakeController.deletedListIds, isEmpty);

        // Dismiss swipe and Confirm
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar lista?'), findsOneWidget);
        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();
        expect(fakeController.deletedListIds, contains('l1'));

        // Tap info icon in AppBar
        await tester.tap(find.byIcon(Icons.info_outline_rounded));
        await tester.pumpAndSettle();
        expect(find.text('About Screen Target'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();

        // Tap FAB
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

      // Toggle item
      await tester.tap(find.text('Queso'));
      await tester.pump();
      expect(fakeController.toggledItemIds, contains('i1'));

      // Collapse completed group
      await tester.tap(find.text('Completados (1)'));
      await tester.pump();
      expect(find.text('Vino'), findsNothing); // collapsed

      // Expand completed group back
      await tester.tap(find.text('Completados (1)'));
      await tester.pump();
      expect(find.text('Vino'), findsOneWidget);

      // Pull to refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();
      expect(fakeController.manualSyncCalled, isTrue);

      // Quick add item
      await tester.enterText(find.byType(TextField), 'Mantequilla');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(fakeController.addedItems, contains('Mantequilla'));

      // Tap edit button in AppBar
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

      // Tap share button
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

      // Go to /lists/new
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      container.read(appRouterProvider).go(AppRoutes.newList);
      await tester.pumpAndSettle();
      expect(find.byType(CreateEditListScreen), findsOneWidget);

      // Go to /list/1
      container.read(appRouterProvider).go(AppRoutes.listDetailPath('1'));
      await tester.pumpAndSettle();
      expect(find.byType(ListDetailScreen), findsOneWidget);

      // Go to /list/1/edit
      container.read(appRouterProvider).go(AppRoutes.editListPath('1'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateEditListScreen), findsOneWidget);

      // Go to /about
      container.read(appRouterProvider).go(AppRoutes.about);
      await tester.pumpAndSettle();
      expect(find.text('Listix'), findsOneWidget);
    });
  });
}

class _ScreensTestListsController extends ListsController {
  final List<ShoppingList> _lists;
  final List<String> createdNames = [];
  final Map<String, String> updatedNames = {};
  final List<String> deletedListIds = [];
  final List<String> addedItems = [];
  final List<String> toggledItemIds = [];
  final List<String> deletedItemIds = [];
  bool manualSyncCalled = false;

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
  Future<void> manualSync() async {
    manualSyncCalled = true;
  }
}
