import 'package:listix/src/features/sync/domain/pending_operation.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/features/collaboration/data/repositories/websocket_collaboration_repository.dart';
import 'package:listix/src/features/collaboration/domain/entities/collaboration_event.dart';
import 'package:listix/src/features/collaboration/domain/repositories/collaboration_repository.dart';
import 'package:listix/src/features/collaboration/presentation/controllers/collaboration_controller.dart';
import 'package:listix/src/features/collaboration/presentation/widgets/join_list_dialog.dart';
import 'package:listix/src/features/collaboration/presentation/widgets/realtime_presence_badge.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/domain/repositories/lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/share_list_sheet.dart';
import 'package:listix/src/features/lists/presentation/screens/home_screen.dart';
import 'package:listix/src/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:listix/src/features/lists/presentation/services/share_service.dart';

class _FakeListsRepoForCollab implements ListsRepository {
  final List<ShoppingList> internalLists;
  bool joinCalled = false;
  String? lastJoinedId;

  _FakeListsRepoForCollab(this.internalLists);

  @override
  Future<List<ShoppingList>> getLists() async => List.from(internalLists);

  @override
  Future<ShoppingList?> getListById(String id) async =>
      internalLists.where((l) => l.id == id).firstOrNull;

  @override
  Future<ShoppingList> createList(String name) async {
    final list = ShoppingList(
      id: 'created_${internalLists.length}',
      name: name,
      createdAt: DateTime.now(),
    );
    internalLists.add(list);
    return list;
  }

  @override
  Future<ShoppingList> joinSharedList(
    String listId,
    String name, {
    String? ownerName,
    String? ownerEmail,
  }) async {
    joinCalled = true;
    lastJoinedId = listId;
    final list = ShoppingList(
      id: listId,
      name: name,
      createdAt: DateTime.now(),
      collaborators: [
        Collaborator(
          id: 'owner_$listId',
          name: ownerName ?? 'Owner',
          email: ownerEmail ?? 'owner@listix.local',
          isOwner: true,
        ),
      ],
    );
    internalLists.add(list);
    return list;
  }

  @override
  Future<ShoppingList> updateListName(String id, String newName) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteList(String id) async {}

  @override
  Future<void> restoreList(ShoppingList list) async {}

  @override
  Future<void> toggleListStar(String listId) async {}

  @override
  Future<void> reorderLists(List<String> orderedListIds) async {}

  @override
  Future<TodoItem> addItem(String listId, String title, {String? id}) async {
    final item = TodoItem(
      id: id ?? 'item_1',
      listId: listId,
      title: title,
      createdAt: DateTime.now(),
    );
    return item;
  }

  @override
  Future<TodoItem> toggleItemCompletion(String listId, String itemId) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteItem(String listId, String itemId) async {}

  @override
  Future<void> restoreItem(TodoItem item) async {}

  @override
  Future<void> reorderItems(String listId, List<String> orderedItemIds) async {}

  @override
  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  }) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      final collab = Collaborator(
        id: 'collab_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        role: role,
      );
      internalLists[idx] = internalLists[idx].copyWith(
        collaborators: [...internalLists[idx].collaborators, collab],
      );
    }
  }

  @override
  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(
        collaborators: internalLists[idx].collaborators.map((c) {
          if (c.id == collaboratorId) return c.copyWith(role: role);
          return c;
        }).toList(),
      );
    }
  }

  @override
  Future<void> applyRemoteCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    await updateCollaboratorRole(listId, collaboratorId, role);
  }

  @override
  Future<void> removeCollaborator(String listId, String collaboratorId) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(
        collaborators: internalLists[idx].collaborators
            .where((c) => c.id != collaboratorId)
            .toList(),
      );
    }
  }

  @override
  Future<void> syncList(String listId) async {}

  @override
  Future<void> setListShared(String listId, bool isShared) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(isShared: isShared);
    }
  }

  @override
  Future<void> applyRemoteItem(TodoItem item) async {
    final idx = internalLists.indexWhere((l) => l.id == item.listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(
        items: [...internalLists[idx].items, item],
      );
    }
  }

  @override
  Future<void> applyRemoteItemToggle(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      final items = internalLists[idx].items.map((i) {
        if (i.id == itemId) return i.copyWith(isCompleted: isCompleted);
        return i;
      }).toList();
      internalLists[idx] = internalLists[idx].copyWith(items: items);
    }
  }

  @override
  Future<void> applyRemoteItemDelete(String listId, String itemId) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(
        items: internalLists[idx].items.where((i) => i.id != itemId).toList(),
      );
    }
  }

  @override
  Future<void> applyRemoteCollaborator(
    String listId,
    Collaborator collaborator,
  ) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(
        collaborators: [...internalLists[idx].collaborators, collaborator],
      );
    }
  }

  @override
  Future<void> applyRemoteCollaboratorRemove(
    String listId,
    String collaboratorId,
  ) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      internalLists[idx] = internalLists[idx].copyWith(
        collaborators: internalLists[idx].collaborators
            .where((c) => c.id != collaboratorId)
            .toList(),
      );
    }
  }

  @override
  Future<void> saveRemoteList(ShoppingList list) async {
    final idx = internalLists.indexWhere((l) => l.id == list.id);
    if (idx != -1) {
      internalLists[idx] = list;
    } else {
      internalLists.add(list);
    }
  }

  @override
  Future<List<PendingOperation>> getPendingOperations({String? listId}) async =>
      [];

  @override
  Future<void> removePendingOperation(String id) async {}

  @override
  Future<void> clearPendingOperationsForList(String listId) async {}
}

class _FakeListsControllerCollab extends ListsController {
  final List<ShoppingList> _initial;

  _FakeListsControllerCollab(this._initial);

  @override
  Future<List<ShoppingList>> build() async => _initial;

  @override
  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  }) async {
    final idx = _initial.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      final collab = Collaborator(
        id: 'c_new',
        name: email.split('@').first,
        email: email,
        role: role,
      );
      _initial[idx] = _initial[idx].copyWith(
        collaborators: [..._initial[idx].collaborators, collab],
        isShared: true,
      );
      state = AsyncData(List.from(_initial));
    }
  }

  @override
  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {
    final idx = _initial.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      _initial[idx] = _initial[idx].copyWith(
        collaborators: _initial[idx].collaborators.map((c) {
          if (c.id == collaboratorId) return c.copyWith(role: role);
          return c;
        }).toList(),
      );
      state = AsyncData(List.from(_initial));
    }
  }

  bool setListSharedCalled = false;
  bool? lastSetSharedValue;

  @override
  Future<void> setListShared(String listId, bool isShared) async {
    setListSharedCalled = true;
    lastSetSharedValue = isShared;
    final idx = _initial.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      _initial[idx] = _initial[idx].copyWith(isShared: isShared);
      state = AsyncData(List.from(_initial));
    }
  }
}

class _FakeShareServiceForCollab implements ShareService {
  String? lastCopiedText;
  String? lastWhatsAppText;
  String? lastGmailSubject;
  String? lastGmailBody;
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
    lastWhatsAppText = text;
    return true;
  }

  @override
  Future<bool> shareToGmail({
    required String subject,
    required String body,
  }) async {
    lastGmailSubject = subject;
    lastGmailBody = body;
    return true;
  }

  @override
  Future<void> copyToClipboard(String text) async {
    lastCopiedText = text;
  }
}

void main() {
  group('CollaborationEvent Tests', () {
    test('Constructors and JSON round-trip serialization', () {
      final now = DateTime.now();
      final item = TodoItem(
        id: 'it1',
        listId: 'l1',
        title: 'Queso Gouda',
        createdAt: now,
      );
      final collab = const Collaborator(
        id: 'c1',
        name: 'Carlos Ruiz',
        email: 'carlos@test.com',
      );

      final joinEvt = CollaborationEvent.join(
        listId: 'l1',
        userEmail: 'user@test.com',
        userName: 'User Test',
      );
      expect(joinEvt.type, CollaborationEventType.joinList);
      expect(joinEvt.listId, 'l1');
      expect(joinEvt.senderEmail, 'user@test.com');

      final presenceEvt = CollaborationEvent.presence(
        listId: 'l1',
        onlineCount: 3,
        onlineUsers: ['u1', 'u2', 'u3'],
      );
      expect(presenceEvt.type, CollaborationEventType.presence);
      expect(presenceEvt.payload['onlineCount'], 3);

      final addEvt = CollaborationEvent.itemAdded(
        listId: 'l1',
        item: item,
        senderEmail: 'user@test.com',
        senderName: 'User Test',
      );
      final jsonAdd = addEvt.toJson();
      final parsedAdd = CollaborationEvent.fromJson(jsonAdd);
      expect(parsedAdd.type, CollaborationEventType.addItem);
      expect(parsedAdd.listId, 'l1');
      expect(parsedAdd.payload['item']['title'], 'Queso Gouda');

      final toggleEvt = CollaborationEvent.itemToggled(
        listId: 'l1',
        itemId: 'it1',
        isCompleted: true,
        senderEmail: 'user@test.com',
        senderName: 'User',
      );
      expect(toggleEvt.payload['isCompleted'], isTrue);

      final delEvt = CollaborationEvent.itemDeleted(
        listId: 'l1',
        itemId: 'it1',
        senderEmail: 'user@test.com',
        senderName: 'User',
      );
      expect(delEvt.payload['itemId'], 'it1');

      final inviteEvt = CollaborationEvent.collaboratorInvited(
        listId: 'l1',
        collaborator: collab,
        senderEmail: 'user@test.com',
        senderName: 'User',
      );
      expect(inviteEvt.payload['collaborator']['email'], 'carlos@test.com');

      final removeEvt = CollaborationEvent.collaboratorRemoved(
        listId: 'l1',
        collaboratorId: 'c1',
        senderEmail: 'user@test.com',
        senderName: 'User',
      );
      expect(removeEvt.payload['collaboratorId'], 'c1');
    });
  });

  group('WebSocketCollaborationRepository Loopback Hub Tests', () {
    late WebSocketCollaborationRepository repo;

    setUp(() {
      repo = WebSocketCollaborationRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('connect, joinList, presence count and events', () async {
      await repo.connect();
      expect(repo.currentStatus, CollaborationStatus.connected);

      final events = <CollaborationEvent>[];
      final sub = repo.eventStream.listen(events.add);

      await repo.joinList(
        'list_test_room',
        userEmail: 'alice@test.com',
        userName: 'Alice',
      );
      expect(repo.activeListId, 'list_test_room');
      expect(repo.activeCollaboratorsCount, 1);

      // Simulate peer action adds an item
      await repo.simulatePeerAction('list_test_room');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.activeCollaboratorsCount, greaterThanOrEqualTo(2));
      expect(
        events.any((e) => e.type == CollaborationEventType.addItem),
        isTrue,
      );

      // Simulate peer toggle action
      await repo.simulatePeerAction('list_test_room', actionType: 'toggle');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        events.any((e) => e.type == CollaborationEventType.toggleItem),
        isTrue,
      );

      // Simulate peer delete action
      await repo.simulatePeerAction('list_test_room', actionType: 'delete');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        events.any((e) => e.type == CollaborationEventType.deleteItem),
        isTrue,
      );

      // Simulate peer invite action
      await repo.simulatePeerAction('list_test_room', actionType: 'invite');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        events.any((e) => e.type == CollaborationEventType.inviteCollaborator),
        isTrue,
      );

      await repo.leaveList(
        'list_test_room',
        userEmail: 'alice@test.com',
        userName: 'Alice',
      );
      expect(repo.activeListId, isNull);

      await sub.cancel();
      await repo.disconnect();
      expect(repo.currentStatus, CollaborationStatus.disconnected);
    });
  });

  group('RealtimePresenceBadge Widget Tests', () {
    testWidgets('renders connected badge with count', (tester) async {
      final repo = WebSocketCollaborationRepository();
      await repo.connect();
      await repo.joinList(
        'list_live',
        userEmail: 'test@me.com',
        userName: 'Tester',
      );

      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [collaborationRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: RealtimePresenceBadge(
                  onTap: () {
                    tapped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RealtimePresenceBadge), findsOneWidget);

      await tester.tap(find.byType(RealtimePresenceBadge));
      expect(tapped, isTrue);

      repo.dispose();
    });
  });

  group('JoinListDialog Widget Tests', () {
    testWidgets('JoinListDialog parses http:// invite link', (tester) async {
      final fakeRepo = _FakeListsRepoForCollab([]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: JoinListDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('invite_code_input')),
        'http://example.com/share?listId=http_list_123&name=ListaHttp',
      );
      await tester.tap(find.text('Unirse'));
      await tester.pumpAndSettle();

      expect(fakeRepo.joinCalled, isTrue);
      expect(fakeRepo.lastJoinedId, 'http_list_123');
    });

    testWidgets('validates input and parses invite link', (tester) async {
      final fakeRepo = _FakeListsRepoForCollab([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: JoinListDialog()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Unirse a una lista compartida'), findsOneWidget);

      // Tap join with empty input -> validation error
      await tester.tap(find.text('Unirse'));
      await tester.pumpAndSettle();
      expect(
        find.text('Código o enlace de invitación inválido'),
        findsOneWidget,
      );

      // Enter valid listix invite link
      await tester.enterText(
        find.byKey(const Key('invite_code_input')),
        'https://listix.app/join?listId=list_remote_99&name=Lista%20Compartida',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unirse'));
      await tester.pumpAndSettle();

      expect(fakeRepo.joinCalled, isTrue);
      expect(fakeRepo.lastJoinedId, 'list_remote_99');
    });

    testWidgets('parses raw listId input successfully', (tester) async {
      final fakeRepo = _FakeListsRepoForCollab([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: JoinListDialog()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter raw list ID
      await tester.enterText(
        find.byKey(const Key('invite_code_input')),
        'custom_id_123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unirse'));
      await tester.pumpAndSettle();

      expect(fakeRepo.joinCalled, isTrue);
      expect(fakeRepo.lastJoinedId, 'custom_id_123');
    });

    testWidgets('handles parse error snackbar and onFieldSubmitted', (
      tester,
    ) async {
      final fakeRepo = _FakeListsRepoForCollab([]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: JoinListDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a URL with trailing slashes so path segments are empty
      await tester.enterText(
        find.byType(TextFormField),
        'https://invalid.com///',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        find.text('Código o enlace de invitación inválido'),
        findsOneWidget,
      );
    });
  });

  group('ShareListSheet Collaboration Features Tests', () {
    testWidgets('invites colleague and copies invite link', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final list = ShoppingList(
        id: 'collab_list_1',
        name: 'Asado con Amigos',
        isShared: true,
        items: const [],
        collaborators: [
          const Collaborator(
            id: 'c_owner',
            name: 'Me',
            email: 'me@listix.local',
            isOwner: true,
          ),
          const Collaborator(
            id: 'c_peer',
            name: 'Juan Perez',
            email: 'juan@listix.local',
            isOwner: false,
          ),
        ],
        createdAt: DateTime.now(),
      );

      final fakeRepo = _FakeListsRepoForCollab([list]);
      final fakeShare = _FakeShareServiceForCollab();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsRepositoryProvider.overrideWithValue(fakeRepo),
            listsControllerProvider.overrideWith(
              () => _FakeListsControllerCollab([list]),
            ),
            shoppingListProvider('collab_list_1').overrideWithValue(list),
            shareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ShareListSheet(listId: 'collab_list_1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify collaboration section elements
      expect(find.byKey(const Key('share_invite_link_button')), findsOneWidget);
      expect(find.text('Juan Perez'), findsOneWidget);

      // Change role via popup menu
      await tester.tap(find.byKey(const ValueKey('change_role_c_peer')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('simulate_peer_button')), findsNothing);
    });

    testWidgets(
      'toggles sharing switch between local only and shared with cloud sync',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final unsharedList = ShoppingList(
          id: 'local_list_only',
          name: 'Notas privadas',
          isShared: false,
          items: const [],
          collaborators: const [],
          createdAt: DateTime.now(),
        );

        final fakeRepo = _FakeListsRepoForCollab([unsharedList]);
        final fakeController = _FakeListsControllerCollab([unsharedList]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              listsRepositoryProvider.overrideWithValue(fakeRepo),
              listsControllerProvider.overrideWith(() => fakeController),
              shoppingListProvider(
                'local_list_only',
              ).overrideWithValue(unsharedList),
              shareServiceProvider.overrideWithValue(
                _FakeShareServiceForCollab(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ShareListSheet(listId: 'local_list_only')),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check initial unshared local-only status
        expect(find.byKey(const Key('toggle_shared_switch')), findsOneWidget);
        expect(find.text('Lista privada (solo local)'), findsOneWidget);
        expect(
          find.text('Los datos se guardan únicamente en tu dispositivo'),
          findsOneWidget,
        );

        // Tap toggle switch to turn ON sharing
        await tester.tap(find.byKey(const Key('toggle_shared_switch')));
        await tester.pumpAndSettle();

        expect(fakeController.setListSharedCalled, isTrue);
        expect(fakeController.lastSetSharedValue, isTrue);
      },
    );

    testWidgets(
      'renders list invite component when sharing is inactive and activates sharing',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final unsharedList = ShoppingList(
          id: 'unshared_list_1',
          name: 'Supermercado',
          isShared: false,
          items: const [],
          collaborators: const [],
          createdAt: DateTime.now(),
        );

        final fakeRepo = _FakeListsRepoForCollab([unsharedList]);
        final fakeController = _FakeListsControllerCollab([unsharedList]);
        final fakeShare = _FakeShareServiceForCollab();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              listsRepositoryProvider.overrideWithValue(fakeRepo),
              listsControllerProvider.overrideWith(() => fakeController),
              shoppingListProvider(
                'unshared_list_1',
              ).overrideWithValue(unsharedList),
              shareServiceProvider.overrideWithValue(fakeShare),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ShareListSheet(listId: 'unshared_list_1')),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify inactive invite component is present
        expect(
          find.byKey(const Key('inactive_share_invite_component')),
          findsOneWidget,
        );
        expect(find.text('Invita a colaborar en esta lista'), findsOneWidget);
        expect(
          find.byKey(const Key('activate_and_share_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('enable_sharing_button')), findsOneWidget);

        // Verify active collaborator management is hidden when inactive
        expect(find.byKey(const Key('share_invite_link_button')), findsNothing);
        expect(find.byKey(const Key('simulate_peer_button')), findsNothing);

        // Tap activate and share button
        await tester.tap(find.byKey(const Key('activate_and_share_button')));
        await tester.pumpAndSettle();

        expect(fakeController.setListSharedCalled, isTrue);
        expect(fakeController.lastSetSharedValue, isTrue);
        expect(find.textContaining('Anonymous Sign-Ins'), findsOneWidget);
      },
    );

    testWidgets(
      'empty collaborators container in dark mode and remove collaborator',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final listWithCollab = ShoppingList(
          id: 'remove_collab_list',
          name: 'Lista Con Colab',
          isShared: true,
          items: const [],
          collaborators: const [
            Collaborator(
              id: 'c1',
              name: 'Ana Perez',
              email: 'ana@listix.local',
              isOwner: false,
            ),
          ],
          createdAt: DateTime.now(),
        );

        final fakeRepo = _FakeListsRepoForCollab([listWithCollab]);
        final fakeController = _FakeListsControllerCollab([listWithCollab]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              listsRepositoryProvider.overrideWithValue(fakeRepo),
              listsControllerProvider.overrideWith(() => fakeController),
              shoppingListProvider(
                'remove_collab_list',
              ).overrideWithValue(listWithCollab),
              shareServiceProvider.overrideWithValue(
                _FakeShareServiceForCollab(),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: ShareListSheet(listId: 'remove_collab_list'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ana Perez'), findsOneWidget);
        await tester.tap(find.byTooltip('Quitar colaborador'));
        await tester.pumpAndSettle();

        // Now with empty collaborators list in dark mode
        final emptyCollabList = listWithCollab.copyWith(
          collaborators: const [],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              listsRepositoryProvider.overrideWithValue(fakeRepo),
              listsControllerProvider.overrideWith(() => fakeController),
              shoppingListProvider(
                'remove_collab_list',
              ).overrideWithValue(emptyCollabList),
              shareServiceProvider.overrideWithValue(
                _FakeShareServiceForCollab(),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: ShareListSheet(listId: 'remove_collab_list'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Aún no hay colaboradores en esta lista.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('enable collaboration button in inactive invite card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final unsharedList = ShoppingList(
        id: 'unshared_2',
        name: 'Sin compartir',
        isShared: false,
        items: const [],
        collaborators: const [],
        createdAt: DateTime.now(),
      );

      final fakeRepo = _FakeListsRepoForCollab([unsharedList]);
      final fakeController = _FakeListsControllerCollab([unsharedList]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsRepositoryProvider.overrideWithValue(fakeRepo),
            listsControllerProvider.overrideWith(() => fakeController),
            shoppingListProvider('unshared_2').overrideWithValue(unsharedList),
            shareServiceProvider.overrideWithValue(
              _FakeShareServiceForCollab(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ShareListSheet(listId: 'unshared_2')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('enable_sharing_button')));
      await tester.pumpAndSettle();

      expect(fakeController.setListSharedCalled, isTrue);
      expect(fakeController.lastSetSharedValue, isTrue);
    });
  });

  group('JoinListDialog and Helpers Tests', () {
    testWidgets('JoinListDialog.show helper opens dialog', (tester) async {
      final fakeRepo = _FakeListsRepoForCollab([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showDialog(
                    context: ctx,
                    builder: (c) => const JoinListDialog(),
                  ),
                  child: const Text('Open Join Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Join Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Unirse a una lista compartida'), findsOneWidget);
    });

    testWidgets(
      'JoinListDialog handles uri without query params and cleans path',
      (tester) async {
        final fakeRepo = _FakeListsRepoForCollab([]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: JoinListDialog()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('invite_code_input')),
          'https://listix.app/join/clean_list_id',
        );
        await tester.tap(find.text('Unirse'));
        await tester.pumpAndSettle();

        expect(fakeRepo.joinCalled, isTrue);
        expect(fakeRepo.lastJoinedId, 'clean_list_id');
      },
    );
  });

  group('RealtimePresenceBadge All States & Modes Tests', () {
    testWidgets(
      'renders all CollaborationStatus in light and dark mode and taps',
      (tester) async {
        var tapped = false;
        for (final isDark in [false, true]) {
          for (final status in CollaborationStatus.values) {
            final count = status == CollaborationStatus.connected ? 3 : 1;
            await tester.pumpWidget(
              ProviderScope(
                key: UniqueKey(),
                overrides: [
                  collaborationControllerProvider.overrideWith(
                    () => _StaticCollabController(
                      CollaborationState(status: status, onlineCount: count),
                    ),
                  ),
                ],
                child: MaterialApp(
                  theme: isDark ? ThemeData.dark() : ThemeData.light(),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: RealtimePresenceBadge(onTap: () => tapped = true),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(RealtimePresenceBadge), findsOneWidget);
            await tester.tap(find.byType(RealtimePresenceBadge));
            expect(tapped, isTrue);
            tapped = false;
          }
        }
      },
    );
  });

  group('CollaborationController and Event Handling Tests', () {
    test('setUserProfile, streams, and remote event handling', () async {
      final fakeRepo = _FakeCollaborationRepoStreams();
      final targetList = ShoppingList(
        id: 'event_list',
        name: 'Lista Eventos',
        items: const [],
        collaborators: const [],
        createdAt: DateTime.now(),
      );
      final fakeListsRepo = _FakeListsRepoForCollab([targetList]);

      final container = ProviderContainer(
        overrides: [
          collaborationRepositoryProvider.overrideWithValue(fakeRepo),
          listsRepositoryProvider.overrideWithValue(fakeListsRepo),
        ],
      );
      addTearDown(container.dispose);

      final collabCtrl = container.read(
        collaborationControllerProvider.notifier,
      );
      collabCtrl.setUserProfile(email: 'nicolas@listix.local', name: 'Nicolas');
      expect(collabCtrl.currentUserEmail, 'nicolas@listix.local');
      expect(collabCtrl.currentUserName, 'Nicolas');

      // Status stream update
      fakeRepo.emitStatus(CollaborationStatus.connected);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(
        container.read(collaborationControllerProvider).status,
        CollaborationStatus.connected,
      );

      // Presence event
      fakeRepo.emitEvent(
        CollaborationEvent.presence(
          listId: 'event_list',
          onlineCount: 4,
          onlineUsers: ['a@test.com', 'b@test.com'],
        ),
      );
      await Future.delayed(const Duration(milliseconds: 20));
      expect(container.read(collaborationControllerProvider).onlineCount, 4);

      // Add item event
      final testItem = TodoItem(
        id: 'new_item_remote',
        listId: 'event_list',
        title: 'Queso Gouda',
        createdAt: DateTime.now(),
      );
      fakeRepo.emitEvent(
        CollaborationEvent.itemAdded(
          listId: 'event_list',
          item: testItem,
          senderEmail: 'other@test.com',
          senderName: 'Other',
        ),
      );

      // Toggle item event
      fakeRepo.emitEvent(
        CollaborationEvent.itemToggled(
          listId: 'event_list',
          itemId: 'new_item_remote',
          isCompleted: true,
          senderEmail: 'other@test.com',
          senderName: 'Other',
        ),
      );

      // Delete item event
      fakeRepo.emitEvent(
        CollaborationEvent.itemDeleted(
          listId: 'event_list',
          itemId: 'new_item_remote',
          senderEmail: 'other@test.com',
          senderName: 'Other',
        ),
      );

      // Invite collaborator event
      const testCollab = Collaborator(
        id: 'remote_c',
        name: 'Camila',
        email: 'camila@test.com',
      );
      fakeRepo.emitEvent(
        CollaborationEvent.collaboratorInvited(
          listId: 'event_list',
          collaborator: testCollab,
          senderEmail: 'other@test.com',
          senderName: 'Other',
        ),
      );

      // Remove collaborator event
      fakeRepo.emitEvent(
        CollaborationEvent.collaboratorRemoved(
          listId: 'event_list',
          collaboratorId: 'remote_c',
          senderEmail: 'other@test.com',
          senderName: 'Other',
        ),
      );

      // Update collaborator role event
      fakeRepo.emitEvent(
        CollaborationEvent.collaboratorRoleUpdated(
          listId: 'event_list',
          collaboratorId: 'remote_c',
          role: CollaboratorRole.admin,
          senderEmail: 'other@test.com',
          senderName: 'Other',
        ),
      );
      fakeRepo.emitEvent(
        CollaborationEvent(
          type: CollaborationEventType.updateCollaboratorRole,
          listId: 'event_list',
          senderEmail: 'other@test.com',
          senderName: 'Other',
          timestamp: DateTime.now(),
          payload: {'collaboratorId': 'remote_c', 'role': 'unknown_role'},
        ),
      );

      await Future.delayed(const Duration(milliseconds: 20));

      // Emit join and leave events
      fakeRepo.emitEvent(
        CollaborationEvent.join(
          listId: 'event_list',
          userEmail: 'joiner@test.com',
          userName: 'Joiner',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 20));

      fakeRepo.emitEvent(
        CollaborationEvent.leave(
          listId: 'event_list',
          userEmail: 'joiner@test.com',
          userName: 'Joiner',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 20));

      // Emit presence event without onlineUsers to test null fallback (line 150)
      fakeRepo.emitEvent(
        CollaborationEvent(
          type: CollaborationEventType.presence,
          listId: 'event_list',
          senderEmail: 'system',
          senderName: 'System',
          timestamp: DateTime.now(),
          payload: {'onlineCount': 5},
        ),
      );
      await Future.delayed(const Duration(milliseconds: 20));

      // Join and leave rooms
      await collabCtrl.joinListRoom('event_list');
      await collabCtrl.leaveListRoom('event_list');

      // Emit event when ref is unmounted (line 151)
      container.dispose();
      fakeRepo.emitEvent(
        CollaborationEvent.presence(listId: 'event_list', onlineCount: 2),
      );
      await Future.delayed(const Duration(milliseconds: 20));
    });
  });

  group('WebSocketCollaborationRepository Full Socket Coverage', () {
    test(
      'WebSocketCollaborationRepository with custom channelFactory coverage',
      () async {
        final inController = StreamController<dynamic>.broadcast();

        final mockChannel = _TestWebSocketChannel(inController);

        final repo = WebSocketCollaborationRepository(
          serverUrl: 'ws://custom.local/socket',
          channelFactory: (_) => mockChannel,
        );

        await repo.connect();
        expect(repo.currentStatus, CollaborationStatus.connected);

        // Send event through real channel
        final testEvent = CollaborationEvent.join(
          listId: 'chan_list',
          userEmail: 'me@listix.local',
          userName: 'Me',
        );
        await repo.sendEvent(testEvent);

        // Trigger stream error to test onError callback
        inController.addError(Exception('custom socket error'));
        await Future.delayed(const Duration(milliseconds: 20));
        expect(repo.currentStatus, CollaborationStatus.connected);

        // Test hub listener when e.senderEmail != _currentUserEmail (lines 164-166)
        await repo.joinList(
          'hub_room_other',
          userEmail: 'me@listix.local',
          userName: 'Me',
        );
        final otherEvent = CollaborationEvent.presence(
          listId: 'hub_room_other',
          onlineCount: 4,
        );
        await repo.sendEvent(otherEvent);
        await Future.delayed(const Duration(milliseconds: 20));

        await repo.disconnect();
        expect(repo.currentStatus, CollaborationStatus.disconnected);

        // Test sendEvent error catch (line 229)
        final throwingChannel = _TestWebSocketChannel(
          StreamController<dynamic>.broadcast(),
          throwOnAdd: true,
        );
        final repoThrow = WebSocketCollaborationRepository(
          serverUrl: 'ws://throw.local/socket',
          channelFactory: (_) => throwingChannel,
        );
        await repoThrow.connect();
        await repoThrow.sendEvent(testEvent);
        expect(repoThrow.currentStatus, CollaborationStatus.error);
        await repoThrow.disconnect();
      },
    );

    test('fallback on invalid and empty URL', () async {
      final emptyRepo = WebSocketCollaborationRepository(serverUrl: '');
      await emptyRepo.connect();
      expect(emptyRepo.currentStatus, CollaborationStatus.connected);
      await emptyRepo.disconnect();

      // Malformed URI throws FormatException inside try block immediately
      final invalidUriRepo = WebSocketCollaborationRepository(
        serverUrl: 'http://[::1:80',
      );
      await invalidUriRepo.connect();
      expect(invalidUriRepo.currentStatus, CollaborationStatus.connected);
      await invalidUriRepo.disconnect();
    });

    test('real local loopback WebSocket server handling', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      WebSocket? serverSocket;

      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          serverSocket = await WebSocketTransformer.upgrade(request);
          serverSocket!.listen((message) {});
        }
      });

      final repo = WebSocketCollaborationRepository(
        serverUrl: 'ws://127.0.0.1:$port',
      );
      await repo.connect();
      expect(repo.currentStatus, CollaborationStatus.connected);

      // Send event on real channel
      final event = CollaborationEvent.join(
        listId: 'ws_list',
        userEmail: 'test@listix.local',
        userName: 'Tester',
      );
      await repo.sendEvent(event);

      // Emit incoming presence event from server
      serverSocket?.add(
        jsonEncode(
          CollaborationEvent.presence(
            listId: 'ws_list',
            onlineCount: 3,
            onlineUsers: ['u1', 'u2', 'u3'],
          ).toJson(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 30));
      expect(repo.activeCollaboratorsCount, 3);

      // Emit malformed packet
      serverSocket?.add('not-valid-json-string');
      await Future.delayed(const Duration(milliseconds: 20));

      // Join room while connected via real socket (lines 158-160, 174)
      await repo.joinList(
        'ws_room',
        userEmail: 'test@listix.local',
        userName: 'Tester',
      );

      // Leave room while connected via real socket (lines 211-214)
      await repo.leaveList(
        'ws_room',
        userEmail: 'test@listix.local',
        userName: 'Tester',
      );

      // Join another room so activeListId != null
      await repo.joinList(
        'ws_room_2',
        userEmail: 'test@listix.local',
        userName: 'Tester',
      );

      // Disconnect when activeListId != null (lines 120-123)
      await repo.disconnect();
      expect(repo.currentStatus, CollaborationStatus.disconnected);

      // Reconnect to test closing
      await repo.connect(customUrl: 'ws://127.0.0.1:$port');
      expect(repo.currentStatus, CollaborationStatus.connected);

      // Close server socket to trigger onDone
      await serverSocket?.close();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(repo.currentStatus, CollaborationStatus.disconnected);

      await repo.disconnect();
      await server.close(force: true);
    });
  });

  group('ListsController Remote Callbacks Unit Tests', () {
    testWidgets('HomeScreen join_list_button opens JoinListDialog', (
      tester,
    ) async {
      final fakeRepo = _FakeListsRepoForCollab([]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsRepositoryProvider.overrideWithValue(fakeRepo),
            listsControllerProvider.overrideWith(
              () => _FakeListsControllerCollab([]),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('join_list_button')));
      await tester.pumpAndSettle();

      expect(find.byType(JoinListDialog), findsOneWidget);
    });

    testWidgets('ListDetailScreen RealtimePresenceBadge opens ShareListSheet', (
      tester,
    ) async {
      final sharedList = ShoppingList(
        id: 'detail_shared_list',
        name: 'Lista Detalle Compartida',
        isShared: true,
        items: const [],
        collaborators: const [],
        createdAt: DateTime.now(),
      );

      final fakeRepo = _FakeListsRepoForCollab([sharedList]);
      final fakeController = _FakeListsControllerCollab([sharedList]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsRepositoryProvider.overrideWithValue(fakeRepo),
            listsControllerProvider.overrideWith(() => fakeController),
            shoppingListProvider(
              'detail_shared_list',
            ).overrideWithValue(sharedList),
            shareServiceProvider.overrideWithValue(
              _FakeShareServiceForCollab(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ListDetailScreen(listId: 'detail_shared_list'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RealtimePresenceBadge), findsOneWidget);
      await tester.tap(find.byType(RealtimePresenceBadge));
      await tester.pumpAndSettle();

      expect(find.byType(ShareListSheet), findsOneWidget);
    });

    test(
      'applyRemoteItem, toggle, delete, collaborators, and setListShared false',
      () async {
        final initialList = ShoppingList(
          id: 'lc_remote_list',
          name: 'Lista Controlador Remoto',
          isShared: true,
          items: [
            TodoItem(
              id: 'item_initial',
              listId: 'lc_remote_list',
              title: 'Café',
              createdAt: DateTime.now(),
            ),
          ],
          collaborators: [
            const Collaborator(
              id: 'collab_1',
              name: 'Laura',
              email: 'laura@test.com',
            ),
          ],
          createdAt: DateTime.now(),
        );

        final fakeRepo = _FakeListsRepoForCollab([initialList]);
        final container = ProviderContainer(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        final controller = container.read(listsControllerProvider.notifier);
        await container.read(listsControllerProvider.future);

        // 1. applyRemoteItem: insert new item
        final newItem = TodoItem(
          id: 'item_new',
          listId: 'lc_remote_list',
          title: 'Leche',
          createdAt: DateTime.now(),
        );
        await controller.applyRemoteItem(newItem);
        var current = container.read(listsControllerProvider).value!.first;
        expect(current.items.length, 2);

        // 2. applyRemoteItem: update existing item
        await controller.applyRemoteItem(
          newItem.copyWith(title: 'Leche de Almendras'),
        );
        current = container.read(listsControllerProvider).value!.first;
        expect(
          current.items.firstWhere((i) => i.id == 'item_new').title,
          'Leche de Almendras',
        );

        // 3. applyRemoteItemToggle
        await controller.applyRemoteItemToggle(
          'lc_remote_list',
          'item_new',
          true,
        );
        current = container.read(listsControllerProvider).value!.first;
        expect(
          current.items.firstWhere((i) => i.id == 'item_new').isCompleted,
          isTrue,
        );

        // 4. applyRemoteItemDelete
        await controller.applyRemoteItemDelete('lc_remote_list', 'item_new');
        current = container.read(listsControllerProvider).value!.first;
        expect(current.items.length, 1);

        // 5. applyRemoteCollaborator: insert new
        const newCollab = Collaborator(
          id: 'collab_2',
          name: 'Mario',
          email: 'mario@test.com',
        );
        await controller.applyRemoteCollaborator('lc_remote_list', newCollab);
        current = container.read(listsControllerProvider).value!.first;
        expect(current.collaborators.length, 2);

        // 6. applyRemoteCollaborator: update existing
        await controller.applyRemoteCollaborator(
          'lc_remote_list',
          newCollab.copyWith(name: 'Mario Rossi'),
        );
        current = container.read(listsControllerProvider).value!.first;
        expect(
          current.collaborators.firstWhere((c) => c.id == 'collab_2').name,
          'Mario Rossi',
        );

        // 7. applyRemoteCollaboratorRemove
        await controller.applyRemoteCollaboratorRemove(
          'lc_remote_list',
          'collab_2',
        );
        current = container.read(listsControllerProvider).value!.first;
        expect(current.collaborators.length, 1);

        await controller.applyRemoteCollaboratorRemove(
          'lc_remote_list',
          'collab_1',
        );
        current = container.read(listsControllerProvider).value!.first;
        expect(current.collaborators, isEmpty);

        // 8. setListShared to false
        await controller.setListShared('lc_remote_list', false);
        current = container.read(listsControllerProvider).value!.first;
        expect(current.isShared, isFalse);
      },
    );

    test(
      'ListsController setListShared rolls back and rethrows on repository error',
      () async {
        final initialList = ShoppingList(
          id: 'error_share_list',
          name: 'Error List',
          createdAt: DateTime.now(),
        );
        final fakeRepo = _ThrowingSetSharedRepo([initialList]);
        final container = ProviderContainer(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(listsControllerProvider.future);
        final controller = container.read(listsControllerProvider.notifier);

        await expectLater(
          () => controller.setListShared('error_share_list', true),
          throwsA(isA<Exception>()),
        );
        expect(
          container.read(listsControllerProvider).value!.first.isShared,
          isFalse,
        );
      },
    );
  });
}

class _StaticCollabController extends CollaborationController {
  final CollaborationState _fixed;
  _StaticCollabController(this._fixed);

  @override
  CollaborationState build() => _fixed;
}

class _FakeCollaborationRepoStreams implements CollaborationRepository {
  final _statusController = StreamController<CollaborationStatus>.broadcast();
  final _eventController = StreamController<CollaborationEvent>.broadcast();
  CollaborationStatus _status = CollaborationStatus.disconnected;
  final int _count = 1;
  String? _activeListId;

  void emitStatus(CollaborationStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void emitEvent(CollaborationEvent e) {
    _eventController.add(e);
  }

  @override
  CollaborationStatus get currentStatus => _status;
  @override
  int get activeCollaboratorsCount => _count;
  @override
  String? get activeListId => _activeListId;
  @override
  Stream<CollaborationStatus> get statusStream => _statusController.stream;
  @override
  Stream<CollaborationEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect({String? customUrl}) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> joinList(
    String listId, {
    required String userEmail,
    required String userName,
  }) async {
    _activeListId = listId;
  }

  @override
  Future<void> leaveList(
    String listId, {
    required String userEmail,
    required String userName,
  }) async {
    if (_activeListId == listId) _activeListId = null;
  }

  @override
  Future<void> sendEvent(CollaborationEvent event) async {}
  @override
  Future<void> simulatePeerAction(String listId, {String? actionType}) async {}

  @override
  void dispose() {
    _statusController.close();
    _eventController.close();
  }
}

class _ThrowingSetSharedRepo extends _FakeListsRepoForCollab {
  _ThrowingSetSharedRepo(super.initial);
  @override
  Future<void> setListShared(String listId, bool isShared) async {
    throw Exception('Error simulado al compartir');
  }
}

class _TestWebSocketSink implements WebSocketSink {
  final bool throwOnAdd;
  _TestWebSocketSink({this.throwOnAdd = false});

  @override
  void add(dynamic data) {
    if (throwOnAdd) throw Exception('Simulated sink error');
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream stream) async {}

  @override
  Future close([int? closeCode, String? closeReason]) async {}

  @override
  Future get done => Future.value();
}

class _TestWebSocketChannel extends StreamChannelMixin
    implements WebSocketChannel {
  final StreamController _streamCtrl;
  final bool throwOnAdd;

  _TestWebSocketChannel(this._streamCtrl, {this.throwOnAdd = false});

  @override
  Stream get stream => _streamCtrl.stream;

  @override
  WebSocketSink get sink => _TestWebSocketSink(throwOnAdd: throwOnAdd);

  @override
  Future<void> get ready => Future.value();

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;
}
