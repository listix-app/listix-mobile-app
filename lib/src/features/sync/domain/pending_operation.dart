import 'dart:convert';

/// Represents the type of entity targeted by a pending sync mutation.
enum PendingEntityType { list, item }

/// Represents the mutation operation type.
enum PendingOpType { upsert, delete }

/// Record representing a local mutation queued for synchronization with Supabase.
class PendingOperation {
  final String id;
  final String listId;
  final PendingEntityType entityType;
  final String entityId;
  final PendingOpType opType;
  final Map<String, dynamic>? payload;
  final int createdAt;

  const PendingOperation({
    required this.id,
    required this.listId,
    required this.entityType,
    required this.entityId,
    required this.opType,
    this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'list_id': listId,
    'entity_type': entityType.name,
    'entity_id': entityId,
    'op_type': opType.name,
    'payload': payload != null ? jsonEncode(payload) : null,
    'created_at': createdAt,
  };

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? decodedPayload;
    final rawPayload = map['payload'];
    if (rawPayload is String && rawPayload.isNotEmpty) {
      try {
        decodedPayload = jsonDecode(rawPayload) as Map<String, dynamic>;
      } catch (_) {
        decodedPayload = null;
      }
    } else if (rawPayload is Map<String, dynamic>) {
      decodedPayload = rawPayload;
    }

    return PendingOperation(
      id: map['id'] as String,
      listId: map['list_id'] as String,
      entityType: PendingEntityType.values.byName(map['entity_type'] as String),
      entityId: map['entity_id'] as String,
      opType: PendingOpType.values.byName(map['op_type'] as String),
      payload: decodedPayload,
      createdAt: map['created_at'] as int,
    );
  }

  @override
  String toString() =>
      'PendingOperation(id: $id, listId: $listId, entity: ${entityType.name}, entityId: $entityId, op: ${opType.name}, createdAt: $createdAt)';
}
