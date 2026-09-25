import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lists/domain/entities/collaborator.dart';
import '../../../lists/domain/entities/todo_item.dart';
import '../../../lists/presentation/controllers/lists_controller.dart';
import '../../domain/entities/collaboration_event.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../../data/repositories/websocket_collaboration_repository.dart';

final collaborationRepositoryProvider = Provider<CollaborationRepository>((
  ref,
) {
  final repo = WebSocketCollaborationRepository();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

class CollaborationState {
  final CollaborationStatus status;
  final int onlineCount;
  final List<String> onlineUsers;
  final String? activeListId;
  final CollaborationEvent? lastEvent;

  const CollaborationState({
    this.status = CollaborationStatus.disconnected,
    this.onlineCount = 1,
    this.onlineUsers = const [],
    this.activeListId,
    this.lastEvent,
  });

  CollaborationState copyWith({
    CollaborationStatus? status,
    int? onlineCount,
    List<String>? onlineUsers,
    String? activeListId,
    CollaborationEvent? lastEvent,
  }) {
    return CollaborationState(
      status: status ?? this.status,
      onlineCount: onlineCount ?? this.onlineCount,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      activeListId: activeListId ?? this.activeListId,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }
}

class CollaborationController extends Notifier<CollaborationState> {
  StreamSubscription<CollaborationStatus>? _statusSub;
  StreamSubscription<CollaborationEvent>? _eventSub;

  String _userEmail = 'me@listix.local';
  String _userName = 'Me';

  String get currentUserEmail => _userEmail;
  String get currentUserName => _userName;

  void setUserProfile({required String email, required String name}) {
    _userEmail = email;
    _userName = name;
  }

  @override
  CollaborationState build() {
    final repo = ref.watch(collaborationRepositoryProvider);

    _statusSub?.cancel();
    _eventSub?.cancel();

    _statusSub = repo.statusStream.listen((status) {
      if (ref.mounted) {
        state = state.copyWith(status: status);
      }
    });

    _eventSub = repo.eventStream.listen((event) {
      if (ref.mounted) {
        _onIncomingEvent(event);
      }
    });

    ref.onDispose(() {
      _statusSub?.cancel();
      _eventSub?.cancel();
    });

    return CollaborationState(
      status: repo.currentStatus,
      onlineCount: repo.activeCollaboratorsCount,
      activeListId: repo.activeListId,
    );
  }

  Future<void> joinListRoom(String listId) async {
    try {
      final repo = ref.read(collaborationRepositoryProvider);
      if (ref.mounted) {
        state = state.copyWith(
          activeListId: listId,
          status: CollaborationStatus.connecting,
        );
      }
      await repo.joinList(listId, userEmail: _userEmail, userName: _userName);
      if (ref.mounted) {
        state = state.copyWith(
          activeListId: listId,
          status: repo.currentStatus,
          onlineCount: repo.activeCollaboratorsCount,
        );
      }
    } catch (_) {}
  }

  Future<void> leaveListRoom(String listId) async {
    try {
      final repo = ref.read(collaborationRepositoryProvider);
      await repo.leaveList(listId, userEmail: _userEmail, userName: _userName);
      if (ref.mounted && state.activeListId == listId) {
        state = state.copyWith(
          activeListId: null,
          onlineCount: 1,
          onlineUsers: const [],
        );
      }
    } catch (_) {}
  }

  Future<void> simulatePeerAction(String listId, {String? actionType}) async {
    try {
      final repo = ref.read(collaborationRepositoryProvider);
      await repo.simulatePeerAction(listId, actionType: actionType);
    } catch (_) {}
  }

  Future<void> broadcastEvent(String listId, CollaborationEvent event) async {
    try {
      final repo = ref.read(collaborationRepositoryProvider);
      await repo.sendEvent(event);
    } catch (_) {}
  }

  void _onIncomingEvent(CollaborationEvent event) {
    state = state.copyWith(lastEvent: event);

    if (event.type == CollaborationEventType.presence) {
      final count = event.payload['onlineCount'] as int? ?? 1;
      final users =
          (event.payload['onlineUsers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      state = state.copyWith(onlineCount: count, onlineUsers: users);
      return;
    }

    // Forward mutating events to ListsController
    try {
      final listsCtrl = ref.read(listsControllerProvider.notifier);

      switch (event.type) {
        case CollaborationEventType.addItem:
          final rawItem = event.payload['item'];
          if (rawItem is Map<String, dynamic>) {
            final item = TodoItem.fromJson(rawItem);
            listsCtrl.applyRemoteItem(item);
          }
          break;
        case CollaborationEventType.toggleItem:
          final itemId = event.payload['itemId'] as String?;
          final isCompleted = event.payload['isCompleted'] as bool? ?? false;
          if (itemId != null) {
            listsCtrl.applyRemoteItemToggle(event.listId, itemId, isCompleted);
          }
          break;
        case CollaborationEventType.deleteItem:
          final itemId = event.payload['itemId'] as String?;
          if (itemId != null) {
            listsCtrl.applyRemoteItemDelete(event.listId, itemId);
          }
          break;
        case CollaborationEventType.inviteCollaborator:
          final rawCollab = event.payload['collaborator'];
          if (rawCollab is Map<String, dynamic>) {
            final collab = Collaborator.fromJson(rawCollab);
            listsCtrl.applyRemoteCollaborator(event.listId, collab);
          }
          break;
        case CollaborationEventType.removeCollaborator:
          final collabId = event.payload['collaboratorId'] as String?;
          if (collabId != null) {
            listsCtrl.applyRemoteCollaboratorRemove(event.listId, collabId);
          }
          break;
        case CollaborationEventType.updateCollaboratorRole:
          final collabId = event.payload['collaboratorId'] as String?;
          final roleName = event.payload['role'] as String?;
          if (collabId != null && roleName != null) {
            final role = CollaboratorRole.values.firstWhere(
              (r) => r.name == roleName,
              orElse: () => CollaboratorRole.member,
            );
            listsCtrl.applyRemoteCollaboratorRole(event.listId, collabId, role);
          }
          break;
        default:
          break;
      }
    } catch (_) {}
  }
}

final collaborationControllerProvider =
    NotifierProvider<CollaborationController, CollaborationState>(
      CollaborationController.new,
    );
