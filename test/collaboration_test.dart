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
  Future<void> addCollaborator(String listId, String email) async {
    final idx = internalLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      final collab = Collaborator(
        id: 'collab_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
      );
      internalLists[idx] = internalLists[idx].copyWith(
        collaborators: [...internalLists[idx].collaborators, collab],
      );
    }
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
}


class _FakeListsControllerCollab extends ListsController {
  final List<ShoppingList> _initial;

  _FakeListsControllerCollab(this._initial);

  @override
  Future<List<ShoppingList>> build() async => _initial;

  @override
  Future<void> addCollaborator(String listId, String email) async {
    final idx = _initial.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      final collab = Collaborator(
        id: 'c_new',
        name: email.split('@').first,
        email: email,
      );
      _initial[idx] = _initial[idx].copyWith(
        collaborators: [..._initial[idx].collaborators, collab],
      );
      state = AsyncData(List.from(_initial));
    }
  }
}

class _FakeShareServiceForCollab implements ShareService {
  String? lastCopiedText;
  String? lastWhatsAppText;
  String? lastGmailSubject;
  String? lastGmailBody;

  @override
  Future<ShareResult> shareWithSystem({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
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
            listsControllerProvider.overrideWith(() => _FakeListsControllerCollab([list])),
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
      expect(find.text('Invitar amigos o colegas'), findsOneWidget);
      expect(find.byKey(const Key('copy_invite_link_button')), findsOneWidget);
      expect(find.text('Juan Perez'), findsOneWidget);

      // Tap Copy Invite Link
      await tester.tap(find.byKey(const Key('copy_invite_link_button')));
      await tester.pumpAndSettle();
      expect(fakeShare.lastCopiedText, contains('listId=collab_list_1'));
      expect(find.text('Enlace copiado al portapapeles'), findsOneWidget);

      // Enter new email to invite
      await tester.enterText(
        find.byKey(const Key('collaborator_email_input')),
        'maria@correo.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invite_collaborator_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Invitación enviada a maria@correo.com'),
        findsOneWidget,
      );

      // Tap peer simulation button
      await tester.tap(find.byKey(const Key('simulate_peer_button')));
      await tester.pumpAndSettle();
      expect(
        find.text('Un colega agregó un producto en tiempo real'),
        findsOneWidget,
      );
    });
  });
}
