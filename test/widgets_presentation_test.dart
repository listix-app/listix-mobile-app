import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/widgets/empty_state_widget.dart';
import 'package:listix/src/core/widgets/sync_indicator.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/share_list_sheet.dart';
import 'package:listix/src/features/lists/presentation/services/share_service.dart';
import 'package:listix/src/features/lists/presentation/widgets/collaborator_tile.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_card.dart';
import 'package:listix/src/features/lists/presentation/widgets/todo_item_tile.dart';

class _FakeListsController extends ListsController {
  final List<ShoppingList> _initial;
  final List<String> syncedListIds = [];

  _FakeListsController(this._initial);

  @override
  Future<List<ShoppingList>> build() async => _initial;

  @override
  Future<void> syncListOnShare(String listId) async {
    syncedListIds.add(listId);
  }
}

class _FakeShareService extends ShareService {
  bool whatsAppShared = false;
  bool gmailShared = false;
  bool copied = false;
  bool systemShared = false;

  @override
  Future<ShareResult> shareWithSystem({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    systemShared = true;
    return const ShareResult('success', ShareResultStatus.success);
  }

  @override
  Future<bool> shareToWhatsApp(String text) async {
    whatsAppShared = true;
    return true;
  }

  @override
  Future<bool> shareToGmail({
    required String subject,
    required String body,
  }) async {
    gmailShared = true;
    return true;
  }

  @override
  Future<void> copyToClipboard(String text) async {
    copied = true;
  }
}

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
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders action button and triggers onAction callback', (
      tester,
    ) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.add,
              title: 'Nueva lista',
              message: 'Crea tu primera lista',
              actionLabel: 'Crear ahora',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Crear ahora'), findsOneWidget);
      await tester.tap(find.text('Crear ahora'));
      expect(actionTriggered, isTrue);
    });
  });

  group('CollaboratorTile Tests', () {
    testWidgets('renders owner badge when isOwner is true', (tester) async {
      final collaborator = Collaborator(
        id: 'c1',
        name: 'Ana García',
        email: 'ana@ejemplo.com',
        isOwner: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaboratorTile(collaborator: collaborator, onRemove: () {}),
          ),
        ),
      );

      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('ana@ejemplo.com'), findsOneWidget);
      expect(find.text('Dueño'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets('renders remove button and triggers onRemove when not owner', (
      tester,
    ) async {
      var removeCalled = false;
      final collaborator = Collaborator(
        id: 'c2',
        name: 'Carlos López',
        email: 'carlos@ejemplo.com',
        isOwner: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaboratorTile(
              collaborator: collaborator,
              onRemove: () {
                removeCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Carlos López'), findsOneWidget);
      expect(find.text('Dueño'), findsNothing);

      final removeBtn = find.byIcon(Icons.close);
      expect(removeBtn, findsOneWidget);

      await tester.tap(removeBtn);
      expect(removeCalled, isTrue);
    });

    testWidgets('renders admin and member badges and handles onRoleChanged', (
      tester,
    ) async {
      CollaboratorRole? changedRole;
      final adminCollab = Collaborator(
        id: 'c_admin',
        name: 'Admin Boss',
        email: 'admin@ejemplo.com',
        role: CollaboratorRole.admin,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaboratorTile(
              collaborator: adminCollab,
              adminLabel: 'Admin',
              memberLabel: 'Miembro',
              onRoleChanged: (role) {
                changedRole = role;
              },
            ),
          ),
        ),
      );

      expect(find.text('Admin'), findsOneWidget);

      // Open popup menu and select member
      await tester.tap(find.byKey(const ValueKey('change_role_c_admin')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      await tester.tap(find.text('Miembro').last);
      await tester.pumpAndSettle();
      expect(changedRole, CollaboratorRole.member);

      // Render member without onRoleChanged
      final memberCollab = Collaborator(
        id: 'c_member',
        name: 'Member Person',
        email: 'member@ejemplo.com',
        role: CollaboratorRole.member,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaboratorTile(
              collaborator: memberCollab,
              adminLabel: 'Admin',
              memberLabel: 'Miembro',
            ),
          ),
        ),
      );

      expect(find.text('Miembro'), findsOneWidget);
    });
  });

  group('TodoItemTile Tests', () {
    final now = DateTime(2026, 9, 22);

    testWidgets('tap triggers onToggle and swipe triggers onDelete', (
      tester,
    ) async {
      var toggleCalled = false;
      var deleteCalled = false;

      final item = TodoItem(
        id: 'item_1',
        listId: 'list_1',
        title: 'Manzanas orgánicas',
        isCompleted: false,
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoItemTile(
              item: item,
              onToggle: () {
                toggleCalled = true;
              },
              onDelete: () {
                deleteCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Manzanas orgánicas'), findsOneWidget);

      await tester.tap(find.text('Manzanas orgánicas'));
      expect(toggleCalled, isTrue);

      await tester.drag(
        find.text('Manzanas orgánicas'),
        const Offset(-500.0, 0.0),
      );
      await tester.pumpAndSettle();
      expect(deleteCalled, isTrue);
    });

    testWidgets('renders completed style with lineThrough', (tester) async {
      final item = TodoItem(
        id: 'item_2',
        listId: 'list_1',
        title: 'Leche de almendras',
        isCompleted: true,
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoItemTile(item: item, onToggle: () {}, onDelete: () {}),
          ),
        ),
      );

      final textFinder = find.ancestor(
        of: find.text('Leche de almendras'),
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      final hasLineThrough = tester
          .widgetList<AnimatedDefaultTextStyle>(textFinder)
          .any((w) => w.style.decoration == TextDecoration.lineThrough);
      expect(hasLineThrough, isTrue);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('ListCard Tests', () {
    final now = DateTime(2026, 9, 22);

    testWidgets('renders Sin items when empty', (tester) async {
      final list = ShoppingList(
        id: 'l1',
        name: 'Lista Vacía',
        items: const [],
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListCard(list: list, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Lista Vacía'), findsOneWidget);
      expect(find.text('Sin items'), findsOneWidget);
    });

    testWidgets('renders Todo listo when all items completed and total > 0', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'l2',
        name: 'Lista Completa',
        items: [
          TodoItem(
            id: 'i1',
            listId: 'l2',
            title: 'Pan',
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

    testWidgets('renders ListCard in dark mode with star toggle', (
      tester,
    ) async {
      var starToggled = false;
      final list = ShoppingList(
        id: 'l_star',
        name: 'Lista Estrellada',
        isStarred: true,
        items: const [],
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ListCard(
              list: list,
              onTap: () {},
              onToggleStar: () {
                starToggled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      expect(starToggled, isTrue);
    });

    testWidgets('renders progress text, handles >3 collaborators, and taps', (
      tester,
    ) async {
      var tapped = false;
      final list = ShoppingList(
        id: 'l3',
        name: 'Asado con amigos',
        isShared: true,
        items: [
          TodoItem(
            id: 'i1',
            listId: 'l3',
            title: 'Carne',
            isCompleted: false,
            createdAt: now,
          ),
          TodoItem(
            id: 'i2',
            listId: 'l3',
            title: 'Carbón',
            isCompleted: true,
            createdAt: now,
          ),
        ],
        collaborators: [
          Collaborator(id: 'c1', name: 'Ana', email: 'ana@a.com'),
          Collaborator(id: 'c2', name: 'Beto', email: 'beto@b.com'),
          Collaborator(id: 'c3', name: 'Carlos', email: 'carlos@c.com'),
          Collaborator(id: 'c4', name: 'Diana', email: 'diana@d.com'),
        ],
        createdAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListCard(
              list: list,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('1 de 2 pendientes'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);

      await tester.tap(find.text('Asado con amigos'));
      expect(tapped, isTrue);
    });

    testWidgets(
      'renders ListCard with color, onArchive and onUnarchive callbacks',
      (tester) async {
        var archived = false;
        var unarchived = false;
        final list = ShoppingList(
          id: 'l_col',
          name: 'Color List',
          color: 0xFFEF4444,
          createdAt: now,
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ListCard(
                list: list,
                onTap: () {},
                onArchive: () => archived = true,
                onUnarchive: () => unarchived = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
        expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);

        await tester.tap(find.byIcon(Icons.archive_outlined));
        expect(archived, isTrue);

        await tester.tap(find.byIcon(Icons.unarchive_outlined));
        expect(unarchived, isTrue);
      },
    );
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
            home: Scaffold(body: ShareListSheet(listId: 'unknown_id')),
          ),
        ),
      );

      expect(find.text('Lista no encontrada'), findsOneWidget);
    });

    testWidgets(
      'renders sheet, shares via system, and verifies WhatsApp, Gmail, Copy text removed',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final list = ShoppingList(
          id: 'share_list',
          name: 'Asado familiar',
          isShared: true,
          items: [
            TodoItem(
              id: 'i1',
              listId: 'share_list',
              title: 'Carne',
              isCompleted: false,
              createdAt: now,
            ),
          ],
          createdAt: now,
        );

        final fakeController = _FakeListsController([list]);
        final fakeShare = _FakeShareService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListProvider('share_list').overrideWithValue(list),
              listsControllerProvider.overrideWith(() => fakeController),
              shareServiceProvider.overrideWithValue(fakeShare),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ShareListSheet(listId: 'share_list')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Compartir "Asado familiar"'), findsOneWidget);
        expect(
          find.byKey(const Key('share_invite_link_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('share_system_tile')), findsNothing);

        // Verify removed options
        expect(find.byKey(const Key('share_whatsapp_tile')), findsNothing);
        expect(find.byKey(const Key('share_gmail_tile')), findsNothing);
        expect(find.byKey(const Key('copy_text_tile')), findsNothing);

        expect(fakeController.syncedListIds, isEmpty);
      },
    );

    testWidgets(
      'ShareListSheet.show helper renders modal properly and actions pop',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final list = ShoppingList(
          id: 'no_collab',
          name: 'Lista sola',
          items: const [],
          createdAt: now,
        );
        final fakeShare = _FakeShareService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListProvider('no_collab').overrideWithValue(list),
              listsControllerProvider.overrideWith(
                () => _FakeListsController([list]),
              ),
              shareServiceProvider.overrideWithValue(fakeShare),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
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
        expect(find.text('Compartir "Lista sola"'), findsOneWidget);
        expect(
          find.byKey(const Key('activate_and_share_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('share_system_tile')), findsNothing);
        expect(find.byKey(const Key('share_whatsapp_tile')), findsNothing);
        expect(find.byKey(const Key('share_gmail_tile')), findsNothing);
        expect(find.byKey(const Key('copy_text_tile')), findsNothing);
      },
    );

    testWidgets('renders ownerOnlyAction message when list.isOwner is false', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'not_owner_list',
        name: 'Lista Compartida Ajena',
        isOwner: false,
        collaborators: const [
          Collaborator(
            id: 'c_owner',
            name: 'Other Person',
            email: 'other@test.com',
            isOwner: true,
          ),
        ],
        createdAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListProvider('not_owner_list').overrideWithValue(list),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ShareListSheet(listId: 'not_owner_list')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Solo el dueño puede modificar esta lista'),
        findsOneWidget,
      );
    });
  });
}
