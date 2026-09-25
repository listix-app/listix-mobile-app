import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../lists/domain/entities/collaborator.dart';
import '../../../lists/domain/entities/shopping_list.dart';
import '../../../lists/domain/entities/todo_item.dart';
import '../../domain/entities/collaboration_exceptions.dart';
import '../../domain/services/invite_token_service.dart';

class JoinResult {
  final ShoppingList list;
  final bool alreadyMember;

  const JoinResult({required this.list, required this.alreadyMember});
}

class SupabaseCollaborationRepository {
  final SupabaseService _supabaseService;

  SupabaseCollaborationRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient? get _client => _supabaseService.client;

  /// Creates a cryptographically secure invitation token, stores only its SHA-256
  /// hash in Supabase with expiration, and returns the public share URL.
  Future<String> createInviteLink({
    required String listId,
    Duration expiration = const Duration(days: 7),
  }) async {
    final token = InviteTokenService.generateSecureToken();
    final tokenHash = InviteTokenService.hashToken(token);
    final expiresAt = DateTime.now().toUtc().add(expiration);

    final client = _client;
    if (client == null || !_supabaseService.isReady) {
      throw const InvalidInviteException('Supabase no está configurado.');
    }

    await _supabaseService.ensureAnonymousAuth();
    await client.rpc(
      'create_list_invite',
      params: {
        'p_list_id': listId,
        'p_token_hash': tokenHash,
        'p_expires_at': expiresAt.toIso8601String(),
      },
    );

    return InviteTokenService.buildInviteUrl(token);
  }

  /// Validates the invitation token hash against Supabase, enforces the 5-member limit,
  /// adds the anonymous user to `list_members`, and returns the populated [ShoppingList].
  Future<JoinResult> joinListByToken({
    required String tokenOrUrl,
    String? displayName,
    String? email,
  }) async {
    final cleanToken =
        InviteTokenService.extractToken(tokenOrUrl) ?? tokenOrUrl.trim();
    if (cleanToken.isEmpty) {
      throw const InvalidInviteException('El código de invitación está vacío');
    }

    final tokenHash = InviteTokenService.hashToken(cleanToken);
    final client = _client;

    if (client == null || !_supabaseService.isReady) {
      throw const InvalidInviteException(
        'Servicio de sincronización no disponible',
      );
    }

    await _supabaseService.ensureAnonymousAuth();

    try {
      final response = await client.rpc(
        'join_list_by_token',
        params: {
          'p_token_hash': tokenHash,
          'p_display_name': displayName ?? 'Colaborador',
          'p_email': email,
        },
      );

      if (response == null || response is! Map) {
        throw const InvalidInviteException();
      }

      final data = Map<String, dynamic>.from(response);
      final rawList = data['list'] as Map<String, dynamic>?;
      if (rawList == null) {
        throw const InvalidInviteException(
          'No se pudo cargar la información de la lista',
        );
      }

      final rawItems = (data['items'] as List?) ?? [];
      final rawMembers = (data['members'] as List?) ?? [];
      final alreadyMember = (data['already_member'] as bool?) ?? false;

      final listId = rawList['id'] as String;
      final listName = (rawList['name'] as String?) ?? 'Lista Compartida';
      final listCreatedAtStr = rawList['created_at'] as String?;
      final listCreatedAt = listCreatedAtStr != null
          ? DateTime.tryParse(listCreatedAtStr) ?? DateTime.now()
          : DateTime.now();

      final items = <TodoItem>[];
      for (final itemMap in rawItems) {
        if (itemMap is! Map) continue;
        final m = Map<String, dynamic>.from(itemMap);
        final itemCreatedStr = m['created_at'] as String?;
        final itemCreatedAt = itemCreatedStr != null
            ? DateTime.tryParse(itemCreatedStr) ?? DateTime.now()
            : DateTime.now();

        items.add(
          TodoItem(
            id: m['id'] as String,
            listId: listId,
            title: (m['title'] as String?) ?? '',
            isCompleted: (m['is_completed'] as bool?) ?? false,
            isSynced: true,
            position: (m['position'] as int?) ?? 0,
            createdAt: itemCreatedAt,
          ),
        );
      }

      final members = <Collaborator>[];
      for (final memberMap in rawMembers) {
        if (memberMap is! Map) continue;
        final m = Map<String, dynamic>.from(memberMap);
        final roleStr = (m['role'] as String?) ?? 'member';
        final isOwner = roleStr == 'owner';
        members.add(
          Collaborator(
            id: (m['user_id'] as String?) ?? (m['id'] as String? ?? ''),
            name:
                (m['display_name'] as String?) ??
                (m['email'] as String?) ??
                'Colaborador',
            email: (m['email'] as String?) ?? '',
            isOwner: isOwner,
            role: isOwner ? CollaboratorRole.owner : CollaboratorRole.member,
          ),
        );
      }

      final shoppingList = ShoppingList(
        id: listId,
        name: listName,
        isSynced: true,
        isStarred: false,
        isShared: true,
        position: 0,
        createdAt: listCreatedAt,
        items: items,
        collaborators: members,
      );

      return JoinResult(list: shoppingList, alreadyMember: alreadyMember);
    } on PostgrestException catch (pe) {
      final msg = pe.message;
      if (msg.contains('LIST_MEMBER_LIMIT_REACHED')) {
        throw const ListMemberLimitReachedException();
      } else if (msg.contains('INVITE_EXPIRED')) {
        throw const InviteExpiredException();
      } else if (msg.contains('INVALID_INVITE')) {
        throw const InvalidInviteException();
      } else if (msg.contains('UNAUTHENTICATED')) {
        throw const UnauthenticatedJoinException();
      }
      throw InvalidInviteException(msg);
    } catch (e) {
      if (e is CollaborationException) rethrow;
      throw InvalidInviteException(e.toString());
    }
  }
}

final supabaseCollaborationRepositoryProvider =
    Provider<SupabaseCollaborationRepository>((ref) {
      final supabaseService = ref.watch(supabaseServiceProvider);
      return SupabaseCollaborationRepository(supabaseService: supabaseService);
    });
