import 'dart:async';
import 'dart:math';

import '../../../lists/domain/entities/collaborator.dart';
import '../../../lists/domain/entities/todo_item.dart';
import '../../domain/entities/collaboration_event.dart';
import '../../domain/repositories/collaboration_repository.dart';

class WebSocketCollaborationRepository implements CollaborationRepository {
  final _statusController = StreamController<CollaborationStatus>.broadcast();
  final _eventController = StreamController<CollaborationEvent>.broadcast();

  CollaborationStatus _currentStatus = CollaborationStatus.disconnected;
  String? _activeListId;
  String _currentUserEmail = 'me@listix.local';
  String _currentUserName = 'Me';
  int _activeCollaboratorsCount = 1;

  static final _hubListeners =
      <String, Set<void Function(CollaborationEvent)>>{};
  static final _hubPresence = <String, Set<String>>{};

  WebSocketCollaborationRepository({String? serverUrl});

  @override
  Stream<CollaborationStatus> get statusStream => _statusController.stream;

  @override
  Stream<CollaborationEvent> get eventStream => _eventController.stream;

  @override
  CollaborationStatus get currentStatus => _currentStatus;

  @override
  int get activeCollaboratorsCount => _activeCollaboratorsCount;

  @override
  String? get activeListId => _activeListId;

  void _updateStatus(CollaborationStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      if (!_statusController.isClosed) {
        _statusController.add(status);
      }
    }
  }

  @override
  Future<void> connect({String? customUrl}) async {
    _updateStatus(CollaborationStatus.connecting);
    _updateStatus(CollaborationStatus.connected);
  }

  void _handleIncomingEvent(CollaborationEvent event) {
    if (event.type == CollaborationEventType.presence) {
      final count = event.payload['onlineCount'] as int? ?? 1;
      _activeCollaboratorsCount = count;
    }
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  @override
  Future<void> disconnect() async {
    if (_activeListId != null) {
      await leaveList(
        _activeListId!,
        userEmail: _currentUserEmail,
        userName: _currentUserName,
      );
    }
    _updateStatus(CollaborationStatus.disconnected);
  }

  @override
  Future<void> joinList(
    String listId, {
    required String userEmail,
    required String userName,
  }) async {
    _activeListId = listId;
    _currentUserEmail = userEmail;
    _currentUserName = userName;

    if (_currentStatus != CollaborationStatus.connected) {
      await connect();
    }

    _hubPresence.putIfAbsent(listId, () => <String>{}).add(userEmail);
    _activeCollaboratorsCount = _hubPresence[listId]?.length ?? 1;

    void listener(CollaborationEvent e) {
      if (e.listId == listId && e.senderEmail != _currentUserEmail) {
        _handleIncomingEvent(e);
      }
    }

    _hubListeners.putIfAbsent(listId, () => {}).add(listener);

    final presence = CollaborationEvent.presence(
      listId: listId,
      onlineCount: _activeCollaboratorsCount,
      onlineUsers: _hubPresence[listId]?.toList() ?? [userEmail],
    );
    _handleIncomingEvent(presence);
  }

  @override
  Future<void> leaveList(
    String listId, {
    required String userEmail,
    required String userName,
  }) async {
    _hubPresence[listId]?.remove(userEmail);
    _activeCollaboratorsCount = max(1, (_hubPresence[listId]?.length ?? 1));
    final presence = CollaborationEvent.presence(
      listId: listId,
      onlineCount: _activeCollaboratorsCount,
      onlineUsers: _hubPresence[listId]?.toList() ?? [],
    );
    _handleIncomingEvent(presence);

    if (_activeListId == listId) {
      _activeListId = null;
    }
  }

  @override
  Future<void> sendEvent(CollaborationEvent event) async {
    final listeners = _hubListeners[event.listId];
    if (listeners != null) {
      for (final listener in listeners.toList()) {
        listener(event);
      }
    }
  }

  @override
  Future<void> simulatePeerAction(String listId, {String? actionType}) async {
    const peerEmail = 'mariana.ruiz@listix.local';
    const peerName = 'Mariana Ruiz';

    _hubPresence.putIfAbsent(listId, () => <String>{}).add(peerEmail);
    _activeCollaboratorsCount = max(2, _hubPresence[listId]?.length ?? 2);

    final presence = CollaborationEvent.presence(
      listId: listId,
      onlineCount: _activeCollaboratorsCount,
      onlineUsers: _hubPresence[listId]?.toList() ?? [peerEmail],
    );
    _handleIncomingEvent(presence);

    if (actionType == 'toggle') {
      final toggleEvent = CollaborationEvent.itemToggled(
        listId: listId,
        itemId: 'simulated_item_toggle',
        isCompleted: true,
        senderEmail: peerEmail,
        senderName: peerName,
      );
      _handleIncomingEvent(toggleEvent);
    } else if (actionType == 'delete') {
      final deleteEvent = CollaborationEvent.itemDeleted(
        listId: listId,
        itemId: 'simulated_item_delete',
        senderEmail: peerEmail,
        senderName: peerName,
      );
      _handleIncomingEvent(deleteEvent);
    } else if (actionType == 'invite') {
      final inviteEvent = CollaborationEvent.collaboratorInvited(
        listId: listId,
        collaborator: const Collaborator(
          id: 'collab_peer_mariana',
          name: peerName,
          email: peerEmail,
          isOwner: false,
        ),
        senderEmail: peerEmail,
        senderName: peerName,
      );
      _handleIncomingEvent(inviteEvent);
    } else {
      final demoTitles = [
        '🥑 Aguacates frescos',
        '🍞 Pan integral artesanal',
        '☕ Café de grano',
        '🧀 Queso mozzarella',
        '🥛 Leche de almendras',
        '🍎 Manzanas verdes',
      ];
      final title = demoTitles[Random().nextInt(demoTitles.length)];
      final item = TodoItem(
        id: 'peer_${DateTime.now().millisecondsSinceEpoch}',
        listId: listId,
        title: title,
        isCompleted: false,
        isSynced: true,
        createdAt: DateTime.now(),
      );

      final addEvent = CollaborationEvent.itemAdded(
        listId: listId,
        item: item,
        senderEmail: peerEmail,
        senderName: peerName,
      );
      _handleIncomingEvent(addEvent);
    }
  }

  @override
  void dispose() {
    _statusController.close();
    _eventController.close();
  }
}
