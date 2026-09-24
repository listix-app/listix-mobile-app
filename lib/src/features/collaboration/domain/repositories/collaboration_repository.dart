import '../entities/collaboration_event.dart';

enum CollaborationStatus { disconnected, connecting, connected, error }

abstract interface class CollaborationRepository {
  Stream<CollaborationStatus> get statusStream;
  Stream<CollaborationEvent> get eventStream;
  CollaborationStatus get currentStatus;
  int get activeCollaboratorsCount;
  String? get activeListId;

  Future<void> connect({String? customUrl});
  Future<void> disconnect();
  Future<void> joinList(
    String listId, {
    required String userEmail,
    required String userName,
  });
  Future<void> leaveList(
    String listId, {
    required String userEmail,
    required String userName,
  });
  Future<void> sendEvent(CollaborationEvent event);
  Future<void> simulatePeerAction(String listId, {String? actionType});
  void dispose();
}
