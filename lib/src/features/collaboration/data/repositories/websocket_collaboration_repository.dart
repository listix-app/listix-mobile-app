import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../lists/domain/entities/collaborator.dart';
import '../../../lists/domain/entities/todo_item.dart';
import '../../domain/entities/collaboration_event.dart';
import '../../domain/repositories/collaboration_repository.dart';

class WebSocketCollaborationRepository implements CollaborationRepository {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  final _statusController = StreamController<CollaborationStatus>.broadcast();
  final _eventController = StreamController<CollaborationEvent>.broadcast();

  CollaborationStatus _currentStatus = CollaborationStatus.disconnected;
  String? _activeListId;
  String _currentUserEmail = 'me@listix.local';
  String _currentUserName = 'Me';
  int _activeCollaboratorsCount = 1;
  final String? _serverUrl;
  bool _useInternalHub = false;

  // Internal loopback hub for local / offline / test collaboration
  static final _hubListeners =
      <String, Set<void Function(CollaborationEvent)>>{};
  static final _hubPresence = <String, Set<String>>{};

  WebSocketCollaborationRepository({String? serverUrl})
    : _serverUrl = serverUrl;

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
    final targetUrl = customUrl ?? _serverUrl;
    _updateStatus(CollaborationStatus.connecting);

    if (targetUrl == null || targetUrl.isEmpty) {
      // Use internal in-memory collaboration hub
      _useInternalHub = true;
      _updateStatus(CollaborationStatus.connected);
      return;
    }

    try {
      final uri = Uri.parse(targetUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _channelSubscription = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final event = CollaborationEvent.fromJson(json);
            _handleIncomingEvent(event);
          } catch (_) {
            // Ignore malformed packets
          }
        },
        onError: (err) {
          _updateStatus(CollaborationStatus.error);
          _fallbackToInternalHub();
        },
        onDone: () {
          _updateStatus(CollaborationStatus.disconnected);
        },
      );

      _useInternalHub = false;
      _updateStatus(CollaborationStatus.connected);
    } catch (_) {
      _fallbackToInternalHub();
    }
  }

  void _fallbackToInternalHub() {
    _useInternalHub = true;
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
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    await _channel?.sink.close();
    _channel = null;
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

    final event = CollaborationEvent.join(
      listId: listId,
      userEmail: userEmail,
      userName: userName,
    );

    if (_useInternalHub) {
      _hubPresence.putIfAbsent(listId, () => <String>{}).add(userEmail);
      _activeCollaboratorsCount = _hubPresence[listId]?.length ?? 1;

      // Register listener for this room
      void listener(CollaborationEvent e) {
        if (e.listId == listId && e.senderEmail != _currentUserEmail) {
          _handleIncomingEvent(e);
        }
      }

      _hubListeners.putIfAbsent(listId, () => {}).add(listener);

      // Emit presence event
      final presence = CollaborationEvent.presence(
        listId: listId,
        onlineCount: _activeCollaboratorsCount,
        onlineUsers: _hubPresence[listId]?.toList() ?? [userEmail],
      );
      _handleIncomingEvent(presence);
    } else {
      await sendEvent(event);
    }
  }

  @override
  Future<void> leaveList(
    String listId, {
    required String userEmail,
    required String userName,
  }) async {
    final event = CollaborationEvent.leave(
      listId: listId,
      userEmail: userEmail,
      userName: userName,
    );

    if (_useInternalHub) {
      _hubPresence[listId]?.remove(userEmail);
      _activeCollaboratorsCount = max(1, (_hubPresence[listId]?.length ?? 1));
      final presence = CollaborationEvent.presence(
        listId: listId,
        onlineCount: _activeCollaboratorsCount,
        onlineUsers: _hubPresence[listId]?.toList() ?? [],
      );
      _handleIncomingEvent(presence);
    } else {
      await sendEvent(event);
    }

    if (_activeListId == listId) {
      _activeListId = null;
    }
  }

  @override
  Future<void> sendEvent(CollaborationEvent event) async {
    if (_useInternalHub) {
      final listeners = _hubListeners[event.listId];
      if (listeners != null) {
        for (final listener in listeners.toList()) {
          listener(event);
        }
      }
    } else if (_channel != null &&
        _currentStatus == CollaborationStatus.connected) {
      try {
        final payload = jsonEncode(event.toJson());
        _channel!.sink.add(payload);
      } catch (_) {
        _updateStatus(CollaborationStatus.error);
      }
    }
  }

  @override
  Future<void> simulatePeerAction(String listId, {String? actionType}) async {
    const peerEmail = 'mariana.ruiz@listix.local';
    const peerName = 'Mariana Ruiz';

    // Simulate peer joining presence
    _hubPresence.putIfAbsent(listId, () => <String>{}).add(peerEmail);
    _activeCollaboratorsCount = max(2, _hubPresence[listId]?.length ?? 2);

    final presence = CollaborationEvent.presence(
      listId: listId,
      onlineCount: _activeCollaboratorsCount,
      onlineUsers: _hubPresence[listId]?.toList() ?? [peerEmail],
    );
    _handleIncomingEvent(presence);

    if (actionType == 'toggle') {
      // Simulate checking an item
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
      // Default: Peer adds a grocery item
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
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _statusController.close();
    _eventController.close();
  }
}
