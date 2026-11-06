import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/features/lists/domain/entities/list_type.dart';

import 'package:go_router/go_router.dart';
import 'package:listix/src/core/config/app_environment.dart';
import 'package:listix/src/features/ads/presentation/widgets/banner_ad_widget.dart';
import 'package:listix/src/features/backup/presentation/screens/backup_screen.dart';
import 'package:listix/src/features/collaboration/presentation/screens/join_invite_screen.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/create_edit_list_screen.dart';
import 'package:listix/src/features/lists/presentation/screens/home_screen.dart';
import 'package:listix/src/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_card.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/theme/app_colors.dart';
import 'package:listix/src/routing/app_router.dart';
import 'package:listix/src/routing/routes.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
    await AppDatabase.instance.database;
  });

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

      await tester.ensureVisible(find.byKey(const Key('list_type_custom')));
      await tester.tap(find.byKey(const Key('list_type_custom')));
      await tester.pumpAndSettle();

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

    testWidgets('shows the five list types before asking for the name', (
      tester,
    ) async {
      final fakeController = _ScreensTestListsController([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CreateEditListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
      for (final type in ListType.values) {
        expect(find.byKey(Key('list_type_${type.name}')), findsOneWidget);
      }
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Opciones'), findsOneWidget);
      expect(find.text('Tareas'), findsOneWidget);
      expect(find.text('Personalizada'), findsOneWidget);
      expect(
        find.text('Productos por categoría, con cantidades y unidades.'),
        findsOneWidget,
      );
    });

    testWidgets('creates the list with the selected type', (tester) async {
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
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('list_type_options')));
      await tester.tap(find.byKey(const Key('list_type_options')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('selected_list_type_label')))
            .data,
        'Opciones',
      );

      await tester.enterText(find.byType(TextFormField), 'Universidades');
      await tester.tap(find.text('Crear lista'));
      await tester.pumpAndSettle();

      expect(fakeController.createdNames, ['Universidades']);
      expect(fakeController.createdTypes, [ListType.options]);
    });

    testWidgets('change type and back return to the type picker', (
      tester,
    ) async {
      final fakeController = _ScreensTestListsController([]);
      final router = GoRouter(
        initialLocation: '/prev',
        routes: [
          GoRoute(
            path: '/prev',
            builder: (ctx, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ctx.push('/lists/new'),
                child: const Text('Go New'),
              ),
            ),
          ),
          GoRoute(
            path: '/lists/new',
            builder: (context, state) => const CreateEditListScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.tap(find.text('Go New'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('list_type_tasks')));
      await tester.tap(find.byKey(const Key('list_type_tasks')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('change_list_type_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('list_type_tasks')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('list_type_market')));
      await tester.tap(find.byKey(const Key('list_type_market')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('list_type_market')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('list_type_market')));
      await tester.tap(find.byKey(const Key('list_type_market')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('list_type_market')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Go New'), findsOneWidget);
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
                CreateEditListScreen(listId: state.pathParameters['id']!),
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

    testWidgets('edit mode lets the list type be changed', (tester) async {
      final list = ShoppingList(
        id: 'edit_target',
        name: 'Lista Vieja',
        type: ListType.shopping,
        createdAt: now,
      );
      final fakeController = _ScreensTestListsController([list]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListProvider('edit_target').overrideWithValue(list),
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: GoRouter(
              initialLocation: '/prev',
              routes: [
                GoRoute(
                  path: '/prev',
                  builder: (ctx, state) => ElevatedButton(
                    onPressed: () => ctx.push('/edit'),
                    child: const Text('Go Edit'),
                  ),
                ),
                GoRoute(
                  path: '/edit',
                  builder: (context, state) =>
                      const CreateEditListScreen(listId: 'edit_target'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go Edit'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('edit_list_type_shopping')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('edit_list_type_tasks')));
      await tester.pump();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(fakeController.updatedTypes['edit_target'], ListType.tasks);
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

    testWidgets(
      'edit list mode shows snackbar and pops when isOwner is false',
      (tester) async {
        final list = ShoppingList(
          id: 'not_owned',
          name: 'Lista Ajena',
          isOwner: false,
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
                  onPressed: () => ctx.push('/list/not_owned/edit'),
                  child: const Text('Go Edit Not Owned'),
                ),
              ),
            ),
            GoRoute(
              path: '/list/:id/edit',
              builder: (context, state) =>
                  CreateEditListScreen(listId: state.pathParameters['id']!),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListProvider('not_owned').overrideWithValue(list),
              listsControllerProvider.overrideWith(() => fakeController),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.tap(find.text('Go Edit Not Owned'));
        await tester.pumpAndSettle();

        expect(
          find.text('Solo el dueño puede modificar esta lista'),
          findsOneWidget,
        );
        expect(find.text('Go Edit Not Owned'), findsOneWidget);
      },
    );

    testWidgets('selects and deselects list color in color picker', (
      tester,
    ) async {
      final fakeController = _ScreensTestListsController([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CreateEditListScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('list_type_custom')));
      await tester.tap(find.byKey(const Key('list_type_custom')));
      await tester.pumpAndSettle();

      final firstColor = AppColors.listColors.first;
      final colorKey = Key(
        'color_picker_${firstColor.toARGB32().toRadixString(16)}',
      );

      // Tap to select
      await tester.tap(find.byKey(colorKey));
      await tester.pumpAndSettle();

      // Tap again to deselect
      await tester.tap(find.byKey(colorKey));
      await tester.pumpAndSettle();
    });

    testWidgets('selects list color in dark mode', (tester) async {
      final fakeController = _ScreensTestListsController([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData.dark(),
            home: const Scaffold(body: CreateEditListScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('list_type_custom')));
      await tester.tap(find.byKey(const Key('list_type_custom')));
      await tester.pumpAndSettle();

      final firstColor = AppColors.listColors.first;
      final colorKey = Key(
        'color_picker_${firstColor.toARGB32().toRadixString(16)}',
      );

      await tester.tap(find.byKey(colorKey));
      await tester.pumpAndSettle();
    });
  });

  group('HomeScreen widget tests', () {
    setUp(() async {
      await AppDatabase.instance.setSetting('list_layout_mode', 'list');
    });

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

    testWidgets('renders no bottom banner when ads are disabled', (
      tester,
    ) async {
      final fakeController = _ScreensTestListsController([]);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsEnabledProvider.overrideWithValue(false),
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BannerAdWidget), findsNothing);
    });

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
        expect(find.byType(ListCard), findsOneWidget);

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
        expect(
          reorderableHomeScreen.proxyDecorator!(
            const SizedBox(),
            0,
            const AlwaysStoppedAnimation(0),
          ),
          isA<Material>(),
        );

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

    testWidgets(
      'search lists filters items, handles empty results, and clears',
      (tester) async {
        final list1 = ShoppingList(
          id: 'l1',
          name: 'Supermercado',
          createdAt: now,
        );
        final list2 = ShoppingList(id: 'l2', name: 'Farmacia', createdAt: now);
        final fakeController = _ScreensTestListsController([list1, list2]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
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
        expect(find.text('Farmacia'), findsOneWidget);

        await tester.tap(find.byKey(const Key('list_search_toggle_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('list_search_input')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('list_search_input')),
          'farm',
        );
        await tester.pumpAndSettle();

        expect(find.text('Farmacia'), findsOneWidget);
        expect(find.text('Supermercado'), findsNothing);

        await tester.enterText(
          find.byKey(const Key('list_search_input')),
          'inexistente',
        );
        await tester.pumpAndSettle();

        expect(find.text('No se encontraron resultados'), findsOneWidget);

        await tester.tap(find.byKey(const Key('list_search_toggle_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('list_search_input')), findsNothing);
        expect(find.text('Supermercado'), findsOneWidget);
        expect(find.text('Farmacia'), findsOneWidget);
      },
    );

    testWidgets(
      'segmented tabs switch between active and archived, and render empty states',
      (tester) async {
        final activeList = ShoppingList(
          id: 'act1',
          name: 'Lista Activa',
          isArchived: false,
          createdAt: now,
        );
        final archivedList = ShoppingList(
          id: 'arc1',
          name: 'Lista Archivada',
          isArchived: true,
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([
          activeList,
          archivedList,
        ]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
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

        expect(find.text('Lista Activa'), findsOneWidget);
        expect(find.text('Lista Archivada'), findsNothing);

        await tester.tap(find.textContaining('Archivadas'));
        await tester.pumpAndSettle();

        expect(find.text('Lista Archivada'), findsOneWidget);
        expect(find.text('Lista Activa'), findsNothing);
      },
    );

    testWidgets(
      'renders empty archived state when tab is archived and no archived lists',
      (tester) async {
        final activeList = ShoppingList(
          id: 'act1',
          name: 'Lista Activa',
          isArchived: false,
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([activeList]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
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

        await tester.tap(find.textContaining('Archivadas'));
        await tester.pumpAndSettle();

        expect(find.text('No hay listas archivadas'), findsOneWidget);
      },
    );

    testWidgets(
      'renders empty active lists state and navigates to new list when all lists are archived',
      (tester) async {
        final archivedList = ShoppingList(
          id: 'arc1',
          name: 'Lista Archivada',
          isArchived: true,
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([archivedList]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
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

        expect(find.text('Tus listas, siempre contigo'), findsOneWidget);
        await tester.tap(find.text('Crear mi primera lista'));
        await tester.pumpAndSettle();

        expect(find.text('New Target'), findsOneWidget);
      },
    );

    testWidgets('archive and unarchive lists with undo snackbars', (
      tester,
    ) async {
      final activeList = ShoppingList(
        id: 'act1',
        name: 'Lista Activa',
        isArchived: false,
        isOwner: true,
        createdAt: now,
      );
      final archivedList = ShoppingList(
        id: 'arc1',
        name: 'Lista Archivada',
        isArchived: true,
        isOwner: true,
        createdAt: now,
      );
      final fakeController = _ScreensTestListsController([
        activeList,
        archivedList,
      ]);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
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

      await tester.tap(
        find.descendant(
          of: find.byType(ListCard),
          matching: find.byIcon(Icons.archive_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Archivar lista?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(fakeController.archivedListIds, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byType(ListCard),
          matching: find.byIcon(Icons.archive_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Archivar lista?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Archivar'));
      await tester.pumpAndSettle();

      expect(fakeController.archivedListIds, contains('act1'));
      expect(find.text('Lista archivada'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(fakeController.unarchivedListIds, contains('act1'));

      await tester.tap(find.textContaining('Archivadas'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(ListCard),
          matching: find.byIcon(Icons.unarchive_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeController.unarchivedListIds, contains('arc1'));
      expect(find.text('Lista restaurada'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(fakeController.archivedListIds, contains('arc1'));
    });

    testWidgets(
      'non-owner list dismissal prompts leave confirmation and leaves list',
      (tester) async {
        final sharedList = ShoppingList(
          id: 'l_shared',
          name: 'Lista Compartida',
          isOwner: false,
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([sharedList]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
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

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('Abandonar lista?'), findsOneWidget);
        expect(
          find.text('Abandonarás "Lista Compartida" y perderás el acceso.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Abandonar'));
        await tester.pumpAndSettle();

        expect(fakeController.deletedListIds, contains('l_shared'));
      },
    );

    testWidgets('HomeScreen bulk delete archived lists confirms and undoes', (
      tester,
    ) async {
      final archivedList1 = ShoppingList(
        id: 'arc1',
        name: 'Archived 1',
        isArchived: true,
        createdAt: now,
      );
      final archivedList2 = ShoppingList(
        id: 'arc2',
        name: 'Archived 2',
        isArchived: true,
        createdAt: now,
      );
      final fakeController = _ScreensTestListsController([
        archivedList1,
        archivedList2,
      ]);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archivadas (2)'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('delete_all_archived_lists_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('delete_all_archived_lists_app_bar_button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('delete_all_archived_lists_app_bar_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar listas archivadas?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(fakeController.deleteArchivedListsCalled, isFalse);

      await tester.tap(
        find.byKey(const Key('delete_all_archived_lists_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar listas archivadas?'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(fakeController.deleteArchivedListsCalled, isTrue);
      expect(find.text('2 listas archivadas eliminadas'), findsOneWidget);
      expect(find.text('Deshacer'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(fakeController.bulkRestoredLists.length, 2);
    });
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

    testWidgets(
      'search items filters items, handles empty results, and clears',
      (tester) async {
        final list = ShoppingList(
          id: 'detail_search',
          name: 'Lista Con Cosas',
          items: [
            TodoItem(
              id: 'it1',
              listId: 'detail_search',
              title: 'Manzanas',
              isCompleted: false,
              createdAt: now,
            ),
            TodoItem(
              id: 'it2',
              listId: 'detail_search',
              title: 'Plátanos',
              isCompleted: true,
              createdAt: now,
            ),
          ],
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([list]);

        final router = GoRouter(
          initialLocation: '/list/detail_search',
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
              shoppingListProvider('detail_search').overrideWithValue(list),
              listsControllerProvider.overrideWith(() => fakeController),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Manzanas'), findsOneWidget);

        await tester.tap(find.byKey(const Key('item_search_toggle_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('item_search_input')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('item_search_input')),
          'plát',
        );
        await tester.pumpAndSettle();

        expect(find.text('Manzanas'), findsNothing);
        expect(find.text('Plátanos'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('item_search_input')),
          'nada',
        );
        await tester.pumpAndSettle();

        expect(find.text('No se encontraron resultados'), findsOneWidget);

        await tester.tap(find.byKey(const Key('item_search_toggle_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('item_search_input')), findsNothing);
        expect(find.text('Manzanas'), findsOneWidget);
      },
    );

    testWidgets('edit item opens dialog, validates input, and updates item', (
      tester,
    ) async {
      final item = TodoItem(
        id: 'item_to_edit',
        listId: 'detail_edit',
        title: 'Queso Original',
        isCompleted: false,
        createdAt: now,
      );
      final list = ShoppingList(
        id: 'detail_edit',
        name: 'Lista Editar',
        items: [item],
        createdAt: now,
      );
      final fakeController = _ScreensTestListsController([list]);

      final router = GoRouter(
        initialLocation: '/list/detail_edit',
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
            shoppingListProvider('detail_edit').overrideWithValue(list),
            listsControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Queso Original'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('edit_item_to_edit')));
      await tester.pumpAndSettle();

      expect(find.text('Detalles del elemento'), findsOneWidget);
      expect(find.byKey(const Key('item_editor_title')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('item_editor_title')), '');
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pump();

      expect(find.text('Por favor ingresa un nombre'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('item_editor_title')),
        'Queso Mozzarella',
      );
      await tester.ensureVisible(find.byKey(const Key('item_editor_save')));
      await tester.tap(find.byKey(const Key('item_editor_save')));
      await tester.pumpAndSettle();

      expect(
        fakeController.updatedItemTitles['item_to_edit'],
        'Queso Mozzarella',
      );
    });

    testWidgets(
      'ListDetailScreen completed item single-tap delete button deletes item',
      (tester) async {
        final item = TodoItem(
          id: 'comp_item_del',
          listId: 'detail_comp_del',
          title: 'Completed Item',
          isCompleted: true,
          createdAt: now,
        );
        final list = ShoppingList(
          id: 'detail_comp_del',
          name: 'Lista Completed Del',
          items: [item],
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([list]);

        final router = GoRouter(
          initialLocation: '/list/detail_comp_del',
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
              shoppingListProvider('detail_comp_del').overrideWithValue(list),
              listsControllerProvider.overrideWith(() => fakeController),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('delete_comp_item_del')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('delete_comp_item_del')));
        await tester.pumpAndSettle();

        expect(fakeController.deletedItemIds, contains('comp_item_del'));
        expect(find.text('"Completed Item" eliminado'), findsOneWidget);
      },
    );

    testWidgets(
      'ListDetailScreen back button navigates to home when canPop is false',
      (tester) async {
        final list = ShoppingList(
          id: 'detail_back',
          name: 'Lista Back',
          items: const [],
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([list]);

        final router = GoRouter(
          initialLocation: '/list/detail_back',
          routes: [
            GoRoute(
              path: '/',
              builder: (ctx, state) => const Text('Root Home Page'),
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
              shoppingListProvider('detail_back').overrideWithValue(list),
              listsControllerProvider.overrideWith(() => fakeController),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Root Home Page'), findsOneWidget);
      },
    );

    testWidgets(
      'ListDetailScreen bulk delete completed items confirms and undoes',
      (tester) async {
        final item1 = TodoItem(
          id: 'i1',
          listId: 'list_bulk',
          title: 'Vino Blanco',
          isCompleted: true,
          createdAt: now,
        );
        final item2 = TodoItem(
          id: 'i2',
          listId: 'list_bulk',
          title: 'Pan',
          isCompleted: true,
          createdAt: now,
        );
        final list = ShoppingList(
          id: 'list_bulk',
          name: 'Lista con completados',
          items: [item1, item2],
          createdAt: now,
        );
        final fakeController = _ScreensTestListsController([list]);

        final router = GoRouter(
          initialLocation: '/list/list_bulk',
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
              shoppingListProvider('list_bulk').overrideWithValue(list),
              listsControllerProvider.overrideWith(() => fakeController),
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
          find.byKey(const Key('delete_completed_items_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('delete_completed_items_app_bar_button')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('delete_completed_items_app_bar_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar items completados?'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(fakeController.deleteCompletedItemsCalled, isFalse);

        await tester.tap(
          find.byKey(const Key('delete_completed_items_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar items completados?'), findsOneWidget);
        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();

        expect(fakeController.deleteCompletedItemsCalled, isTrue);
        expect(find.text('2 items completados eliminados'), findsOneWidget);
        expect(find.text('Deshacer'), findsOneWidget);

        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();
        expect(fakeController.bulkRestoredItems.length, 2);
      },
    );
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

      container.read(appRouterProvider).go(AppRoutes.backup);
      await tester.pumpAndSettle();
      expect(find.byType(BackupScreen), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.joinListPath('token-123'));
      await tester.pumpAndSettle();
      expect(find.byType(JoinInviteScreen), findsOneWidget);

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    });

    testWidgets(
      'handles listix://join/<token> deep link and routes to JoinInviteScreen',
      (tester) async {
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

        // Deep link via router.go
        container
            .read(appRouterProvider)
            .go('listix://join/sample-invite-token');
        await tester.pumpAndSettle();
        expect(find.byType(JoinInviteScreen), findsOneWidget);
        final inviteScreen = tester.widget<JoinInviteScreen>(
          find.byType(JoinInviteScreen),
        );
        expect(inviteScreen.token, 'sample-invite-token');

        // Deep link with query parameters via routeInformationProvider
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .didPushRouteInformation(
              RouteInformation(
                uri: Uri.parse('listix://join/pushed-token-456?source=invite'),
              ),
            );
        await tester.pumpAndSettle();
        expect(find.byType(JoinInviteScreen), findsOneWidget);
        final pushedScreen = tester.widget<JoinInviteScreen>(
          find.byType(JoinInviteScreen),
        );
        expect(pushedScreen.token, 'pushed-token-456');

        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      },
    );

    testWidgets(
      'handles listix://join/<invite_code> deep link with short code e.g. K7M4XP2Q',
      (tester) async {
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

        // Deep link via router.go with short code
        container.read(appRouterProvider).go('listix://join/K7M4XP2Q');
        await tester.pumpAndSettle();
        expect(find.byType(JoinInviteScreen), findsOneWidget);
        final inviteScreen = tester.widget<JoinInviteScreen>(
          find.byType(JoinInviteScreen),
        );
        expect(inviteScreen.token, 'K7M4XP2Q');

        // Deep link with lowercase short code and query params
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .didPushRouteInformation(
              RouteInformation(
                uri: Uri.parse('listix://join/k7m4xp2q?source=share'),
              ),
            );
        await tester.pumpAndSettle();
        expect(find.byType(JoinInviteScreen), findsOneWidget);
        final pushedScreen = tester.widget<JoinInviteScreen>(
          find.byType(JoinInviteScreen),
        );
        expect(pushedScreen.token, 'K7M4XP2Q');

        // Deep link via HTTPS invite URL
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .didPushRouteInformation(
              RouteInformation(
                uri: Uri.parse(
                  'https://listix-worker.onrender.com/join/K7M4XP2Q',
                ),
              ),
            );
        await tester.pumpAndSettle();
        expect(find.byType(JoinInviteScreen), findsOneWidget);
        final httpsScreen = tester.widget<JoinInviteScreen>(
          find.byType(JoinInviteScreen),
        );
        expect(httpsScreen.token, 'K7M4XP2Q');

        container
            .read(appRouterProvider)
            .routeInformationProvider
            .didPushRouteInformation(
              RouteInformation(uri: Uri.parse('https://api.listix.app/join')),
            );
        await tester.pumpAndSettle();
        expect(find.byType(JoinInviteScreen), findsOneWidget);

        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      },
    );

    testWidgets(
      'handles cold start with listix://join/<token> defaultRouteName',
      (tester) async {
        tester.platformDispatcher.defaultRouteNameTestValue =
            'listix://join/cold-start-token';
        addTearDown(() {
          tester.platformDispatcher.clearDefaultRouteNameTestValue();
        });

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
        expect(find.byType(JoinInviteScreen), findsOneWidget);
        final inviteScreen = tester.widget<JoinInviteScreen>(
          find.byType(JoinInviteScreen),
        );
        expect(inviteScreen.token, 'cold-start-token');

        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      },
    );
  });
}

class _ScreensTestListsController extends ListsController {
  final List<ShoppingList> _lists;
  final List<String> createdNames = [];
  final List<ListType> createdTypes = [];
  final Map<String, String> updatedNames = {};
  final Map<String, ListType> updatedTypes = {};
  final List<String> deletedListIds = [];
  final List<ShoppingList> restoredLists = [];
  final List<String> starredListIds = [];
  final List<String> addedItems = [];
  final List<String> toggledItemIds = [];
  final List<String> deletedItemIds = [];
  final List<TodoItem> restoredItems = [];
  final List<String> archivedListIds = [];
  final List<String> unarchivedListIds = [];
  final Map<String, String> updatedItemTitles = {};
  bool manualSyncCalled = false;
  bool reorderedListsCalled = false;
  bool reorderedItemsCalled = false;

  _ScreensTestListsController(this._lists);

  @override
  Future<List<ShoppingList>> build() async => _lists;

  @override
  Future<void> archiveList(String listId) async {
    archivedListIds.add(listId);
  }

  @override
  Future<void> unarchiveList(String listId) async {
    unarchivedListIds.add(listId);
  }

  @override
  Future<void> updateItem(String listId, String itemId, String newTitle) async {
    updatedItemTitles[itemId] = newTitle;
  }

  @override
  Future<void> updateItemDetails(TodoItem item) async {
    updatedItemTitles[item.id] = item.title;
  }

  @override
  Future<ShoppingList> createList(
    String name, {
    int? color,
    ListType type = ListType.custom,
  }) async {
    createdNames.add(name);
    createdTypes.add(type);
    return ShoppingList(
      id: 'created_new',
      name: name,
      type: type,
      color: color,
      createdAt: DateTime(2026, 9, 22),
    );
  }

  @override
  Future<ShoppingList> joinListByInviteToken(
    String tokenOrUrl, {
    String? displayName,
    String? email,
  }) async {
    return ShoppingList(
      id: 'token_list',
      name: 'Lista Compartida',
      createdAt: DateTime(2026, 9, 22),
    );
  }

  @override
  Future<void> updateListName(
    String listId,
    String newName, {
    int? color,
    ListType? type,
  }) async {
    updatedNames[listId] = newName;
    if (type != null) updatedTypes[listId] = type;
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
  Future<void> addItem(String listId, String title, {TodoItem? details}) async {
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

  bool deleteArchivedListsCalled = false;
  final List<ShoppingList> bulkRestoredLists = [];
  bool deleteCompletedItemsCalled = false;
  final List<TodoItem> bulkRestoredItems = [];

  @override
  Future<List<ShoppingList>> deleteArchivedListsWithUndo() async {
    deleteArchivedListsCalled = true;
    return _lists.where((l) => l.isArchived).toList();
  }

  @override
  Future<void> restoreLists(List<ShoppingList> lists) async {
    bulkRestoredLists.addAll(lists);
  }

  @override
  Future<List<TodoItem>> deleteCompletedItemsWithUndo(String listId) async {
    deleteCompletedItemsCalled = true;
    final list = _lists.where((l) => l.id == listId).firstOrNull;
    return list?.items.where((i) => i.isCompleted).toList() ?? const [];
  }

  @override
  Future<void> restoreItems(String listId, List<TodoItem> items) async {
    bulkRestoredItems.addAll(items);
  }
}
