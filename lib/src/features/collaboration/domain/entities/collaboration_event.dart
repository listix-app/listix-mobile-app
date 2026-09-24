import '../../../lists/domain/entities/collaborator.dart';
import '../../../lists/domain/entities/todo_item.dart';

enum CollaborationEventType {
  joinList,
  leaveList,
  presence,
  addItem,
  deleteItem,
  toggleItem,
  inviteCollaborator,
  removeCollaborator,
  updateCollaboratorRole,
}

class CollaborationEvent {
  final CollaborationEventType type;
  final String listId;
  final String senderEmail;
  final String senderName;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const CollaborationEvent({
    required this.type,
    required this.listId,
    required this.senderEmail,
    required this.senderName,
    required this.timestamp,
    this.payload = const {},
  });

  factory CollaborationEvent.join({
    required String listId,
    required String userEmail,
    required String userName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.joinList,
      listId: listId,
      senderEmail: userEmail,
      senderName: userName,
      timestamp: DateTime.now(),
    );
  }

  factory CollaborationEvent.leave({
    required String listId,
    required String userEmail,
    required String userName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.leaveList,
      listId: listId,
      senderEmail: userEmail,
      senderName: userName,
      timestamp: DateTime.now(),
    );
  }

  factory CollaborationEvent.presence({
    required String listId,
    required int onlineCount,
    List<String> onlineUsers = const [],
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.presence,
      listId: listId,
      senderEmail: 'system',
      senderName: 'System',
      timestamp: DateTime.now(),
      payload: {'onlineCount': onlineCount, 'onlineUsers': onlineUsers},
    );
  }

  factory CollaborationEvent.itemAdded({
    required String listId,
    required TodoItem item,
    required String senderEmail,
    required String senderName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.addItem,
      listId: listId,
      senderEmail: senderEmail,
      senderName: senderName,
      timestamp: DateTime.now(),
      payload: {'item': item.toJson()},
    );
  }

  factory CollaborationEvent.itemDeleted({
    required String listId,
    required String itemId,
    required String senderEmail,
    required String senderName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.deleteItem,
      listId: listId,
      senderEmail: senderEmail,
      senderName: senderName,
      timestamp: DateTime.now(),
      payload: {'itemId': itemId},
    );
  }

  factory CollaborationEvent.itemToggled({
    required String listId,
    required String itemId,
    required bool isCompleted,
    required String senderEmail,
    required String senderName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.toggleItem,
      listId: listId,
      senderEmail: senderEmail,
      senderName: senderName,
      timestamp: DateTime.now(),
      payload: {'itemId': itemId, 'isCompleted': isCompleted},
    );
  }

  factory CollaborationEvent.collaboratorInvited({
    required String listId,
    required Collaborator collaborator,
    required String senderEmail,
    required String senderName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.inviteCollaborator,
      listId: listId,
      senderEmail: senderEmail,
      senderName: senderName,
      timestamp: DateTime.now(),
      payload: {'collaborator': collaborator.toJson()},
    );
  }

  factory CollaborationEvent.collaboratorRemoved({
    required String listId,
    required String collaboratorId,
    required String senderEmail,
    required String senderName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.removeCollaborator,
      listId: listId,
      senderEmail: senderEmail,
      senderName: senderName,
      timestamp: DateTime.now(),
      payload: {'collaboratorId': collaboratorId},
    );
  }

  factory CollaborationEvent.collaboratorRoleUpdated({
    required String listId,
    required String collaboratorId,
    required CollaboratorRole role,
    required String senderEmail,
    required String senderName,
  }) {
    return CollaborationEvent(
      type: CollaborationEventType.updateCollaboratorRole,
      listId: listId,
      senderEmail: senderEmail,
      senderName: senderName,
      timestamp: DateTime.now(),
      payload: {'collaboratorId': collaboratorId, 'role': role.name},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'listId': listId,
    'senderEmail': senderEmail,
    'senderName': senderName,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'payload': payload,
  };

  factory CollaborationEvent.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'presence';
    final type = CollaborationEventType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => CollaborationEventType.presence,
    );

    return CollaborationEvent(
      type: type,
      listId: json['listId'] as String? ?? '',
      senderEmail: json['senderEmail'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          listId == other.listId &&
          senderEmail == other.senderEmail &&
          senderName == other.senderName &&
          timestamp.millisecondsSinceEpoch ==
              other.timestamp.millisecondsSinceEpoch;

  @override
  int get hashCode => Object.hash(
    type,
    listId,
    senderEmail,
    senderName,
    timestamp.millisecondsSinceEpoch,
  );
}
