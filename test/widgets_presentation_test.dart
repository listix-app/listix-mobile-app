import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/widgets/empty_state_widget.dart';
import 'package:listix/src/core/widgets/sync_indicator.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/share_list_sheet.dart';
import 'package:listix/src/features/lists/presentation/widgets/collaborator_tile.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_card.dart';
import 'package:listix/src/features/lists/presentation/widgets/todo_item_tile.dart';

void main() {
  group('EmptyStateWidget Tests', () {
    testWidgets('renders title and message without action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'Vacío',
              message: 'Nada por aquí',
            ),
          ),
        ),
      );

      expect(find.text('Vacío'), findsOneWidget);
      expect(find.text('Nada por aquí'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders action button and triggers onAction callback', (
      tester,
    ) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.add,
              title: 'Crea tu lista',
              message: 'Comienza ahora',
              actionLabel: 'Crear ahora',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Crear ahora'), findsOneWidget);
      await tester.tap(find.text('Crear ahora'));
      await tester.pump();
      expect(actionTapped, isTrue);
    });
  });

  group('CollaboratorTile Tests', () {
    testWidgets('renders owner badge when isOwner is true', (tester) async {
      const collab = Collaborator(
        id: 'c1',
        name: 'Maria Duena',
        email: 'maria@test.com',
        isOwner: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CollaboratorTile(collaborator: collab)),
        ),
      );

      expect(find.text('Dueño'), findsOneWidget);
      expect(find.text('MD'), findsOneWidget);
      expect(find.text('Maria Duena'), findsOneWidget);
      expect(find.text('maria@test.com'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders remove button and triggers onRemove when not owner', (
      tester,
    ) async {
      bool removed = false;
      const collab = Collaborator(
        id: 'c2',
        name: 'Juan Perez',
        email: 'juan@test.com',
        isOwner: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaboratorTile(
              collaborator: collab,
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      expect(find.text('Dueño'), findsNothing);
      expect(find.byType(IconButton), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(removed, isTrue);
    });
  });

  group('TodoItemTile Tests', () {
    final now = DateTime(2026, 9, 22);

    testWidgets('tap triggers onToggle and swipe triggers onDelete', (
      tester,
    ) async {
      bool toggled = false;
      bool deleted = false;

      final item = TodoItem(
        id: 'item_1',
        listId: 'l1',
        title: 'Comprar leche de almendras',
        isCompleted: false,
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoItemTile(
              item: item,
              onToggle: () => toggled = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.text('Comprar leche de almendras'), findsOneWidget);

      // Tap to toggle
      await tester.tap(find.byType(TodoItemTile));
      await tester.pump();
      expect(toggled, isTrue);

      // Swipe to delete
      await tester.drag(find.byType(TodoItemTile), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('renders completed style with lineThrough', (tester) async {
      final completedItem = TodoItem(
        id: 'item_2',
        listId: 'l1',
        title: 'Item completado',
        isCompleted: true,
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoItemTile(
              item: completedItem,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('ListCard Tests', () {
    final now = DateTime(2026, 9, 22);

    testWidgets('renders Sin items when empty', (tester) async {
      final list = ShoppingList(id: '1', name: 'Lista vacía', createdAt: now);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListCard(list: list, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Sin items'), findsOneWidget);
    });

    testWidgets('renders Todo listo when all items completed and total > 0', (
      tester,
    ) async {
      final list = ShoppingList(
        id: '2',
        name: 'Todo hecho',
        items: [
          TodoItem(
            id: 't1',
            listId: '2',
            title: 'Item',
            isCompleted: true,
            createdAt: now,
          ),
        ],
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListCard(list: list, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Todo listo ✓'), findsOneWidget);
    });

    testWidgets('renders progress text, handles >3 collaborators, and taps', (
      tester,
    ) async {
      bool tapped = false;
      final collabs = List.generate(
        5,
        (i) => Collaborator(id: '$i', name: 'User $i', email: 'u$i@test.com'),
      );
      final list = ShoppingList(
        id: '3',
        name: 'Supermercado',
        items: [
          TodoItem(
            id: 't1',
            listId: '3',
            title: 'Pan',
            isCompleted: false,
            createdAt: now,
          ),
          TodoItem(
            id: 't2',
            listId: '3',
            title: 'Agua',
            isCompleted: true,
            createdAt: now,
          ),
        ],
        collaborators: collabs,
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListCard(list: list, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('1 de 2 pendientes'), findsOneWidget);
      expect(
        find.text('+3'),
        findsOneWidget,
      ); // 5 collaborators - 2 visible = 3 remaining

      await tester.tap(find.byType(ListCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('SyncIndicator Tests', () {
    testWidgets(
      'renders synced, pending with tooltip, and pending without tooltip',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SyncIndicator(isSynced: true),
                  SyncIndicator(isSynced: false, showTooltip: true),
                  SyncIndicator(isSynced: false, showTooltip: false),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(Tooltip), findsOneWidget);
      },
    );
  });

  group('ShareListSheet Tests', () {
    final now = DateTime(2026, 9, 22);

    testWidgets('renders not found when list is null', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ShareListSheet(listId: 'non-existent')),
          ),
        ),
      );

      expect(find.text('Lista no encontrada'), findsOneWidget);
    });

    testWidgets(
      'renders sheet, copies link, and invites email with validation',
      (tester) async {
        final list = ShoppingList(
          id: 'share_list',
          name: 'Asado familiar',
          collaborators: const [
            Collaborator(
              id: 'owner',
              name: 'Dueño',
              email: 'owner@test.com',
              isOwner: true,
            ),
            Collaborator(
              id: 'c1',
              name: 'Invitado',
              email: 'inv@test.com',
              isOwner: false,
            ),
          ],
          createdAt: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListProvider('share_list').overrideWithValue(list),
              listsControllerProvider.overrideWith(
                () => _FakeListsController([list]),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ShareListSheet(listId: 'share_list')),
            ),
          ),
        );

        expect(find.text('Compartir "Asado familiar"'), findsOneWidget);
        expect(find.text('Copiar enlace de invitación'), findsOneWidget);
        expect(find.text('Colaboradores (2)'), findsOneWidget);

        // Copy link
        await tester.tap(find.text('Copiar enlace de invitación'));
        await tester.pumpAndSettle();
        expect(
          find.text('Enlace de invitación copiado al portapapeles'),
          findsOneWidget,
        );

        // Submit empty email validation
        await tester.tap(find.text('Invitar'));
        await tester.pumpAndSettle();
        expect(find.text('Ingresa un correo'), findsOneWidget);

        // Submit invalid email
        await tester.enterText(find.byType(TextFormField), 'bademail');
        await tester.tap(find.text('Invitar'));
        await tester.pumpAndSettle();
        expect(find.text('Correo no válido'), findsOneWidget);

        // Submit valid email
        await tester.enterText(find.byType(TextFormField), 'valido@correo.com');
        await tester.tap(find.text('Invitar'));
        await tester.pumpAndSettle();
        expect(
          find.text('Invitación enviada a valido@correo.com'),
          findsOneWidget,
        );

        // Remove collaborator
        expect(find.byTooltip('Quitar colaborador'), findsOneWidget);
        await tester.tap(find.byTooltip('Quitar colaborador'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'renders empty collaborators text and ShareListSheet.show helper',
      (tester) async {
        final emptyCollabList = ShoppingList(
          id: 'no_collab',
          name: 'Lista sola',
          collaborators: const [],
          createdAt: now,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListProvider(
                'no_collab',
              ).overrideWithValue(emptyCollabList),
              listsControllerProvider.overrideWith(
                () => _FakeListsController([emptyCollabList]),
              ),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => ShareListSheet.show(ctx, 'no_collab'),
                    child: const Text('Open Modal'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        expect(
          find.text('Aún no hay colaboradores en esta lista.'),
          findsOneWidget,
        );
      },
    );
  });
}

class _FakeListsController extends ListsController {
  final List<ShoppingList> _initial;
  _FakeListsController(this._initial);

  @override
  Future<List<ShoppingList>> build() async => _initial;

  @override
  Future<void> addCollaborator(String listId, String email) async {}

  @override
  Future<void> removeCollaborator(String listId, String collaboratorId) async {}
}
