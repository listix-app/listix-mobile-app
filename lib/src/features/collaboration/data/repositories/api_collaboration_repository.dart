import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/auth_session_service.dart';
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

class ApiCollaborationRepository {
  final ApiClient _apiClient;
  final AuthSessionService _authSession;

  ApiCollaborationRepository({
    ApiClient? apiClient,
    AuthSessionService? authSession,
  }) : _apiClient = apiClient ?? ApiClient(),
       _authSession = authSession ?? AuthSessionService.instance;

  Future<String> createInviteLink({
    required String listId,
    Duration expiration = const Duration(days: 7),
  }) async {
    // coverage:ignore-start
    if (!_authSession.isReady) {
      await _authSession.ensureInitialized();
    }
    // coverage:ignore-end
    if (!_authSession.isReady) {
      throw const InvalidInviteException('Servicio de API no configurado.');
    }

    var response = await _apiClient.post('/lists/$listId/invites');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final inviteUrl = data['inviteUrl'] as String?;
      if (inviteUrl != null && inviteUrl.isNotEmpty) {
        return inviteUrl;
      }
      throw const InvalidInviteException('Respuesta de invitación inválida');
    }

    // coverage:ignore-start
    if (response.statusCode == 404) {
      try {
        final upsertRes = await _apiClient.put(
          '/lists/$listId',
          body: {
            'name': 'Lista',
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
        if (upsertRes.statusCode >= 200 && upsertRes.statusCode < 300) {
          response = await _apiClient.post('/lists/$listId/invites');
          if (response.statusCode >= 200 && response.statusCode < 300) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final inviteUrl = data['inviteUrl'] as String?;
            if (inviteUrl != null && inviteUrl.isNotEmpty) {
              return inviteUrl;
            }
          }
        }
      } catch (_) {}
    }
    // coverage:ignore-end

    _handleError(response);
  }

  Future<Map<String, dynamic>> validateInvite(String credential) async {
    final clean =
        InviteTokenService.extractToken(credential) ?? credential.trim();
    if (clean.isEmpty) {
      throw const InvalidInviteException('El código de invitación está vacío');
    }

    final response = await _apiClient.get(
      '/invites/$clean',
      requiresAuth: false,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final valid = data['valid'] as bool? ?? false;
      if (!valid) {
        final errorCode = data['errorCode'] as String?;
        final message = data['message'] as String?;
        _throwDomainException(errorCode, message);
      }
      return data;
    }

    _handleError(response);
  }

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

    if (!_authSession.isReady) {
      throw const InvalidInviteException('Servicio de API no configurado');
    }

    final body = <String, dynamic>{
      'credential': cleanToken,
      'displayName': displayName ?? 'Colaborador',
      if (email != null && email.isNotEmpty) 'email': email,
    };

    final response = await _apiClient.post('/invites/join', body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['list'] as Map<String, dynamic>?;
      if (rawList == null) {
        throw const InvalidInviteException(
          'No se pudo cargar la información de la lista',
        );
      }

      final rawItems = (data['items'] as List?) ?? [];
      final rawMembers = (data['members'] as List?) ?? [];
      final alreadyMember = (data['alreadyMember'] as bool?) ?? false;

      final listId = rawList['id'] as String;
      final listName = (rawList['name'] as String?) ?? 'Lista Compartida';
      final listCreatedAtStr = rawList['createdAt'] as String?;
      final listCreatedAt = listCreatedAtStr != null
          ? DateTime.tryParse(listCreatedAtStr) ?? DateTime.now()
          : DateTime.now();

      final items = <TodoItem>[];
      for (final itemMap in rawItems) {
        if (itemMap is! Map) continue;
        final m = Map<String, dynamic>.from(itemMap);
        final itemCreatedStr = m['createdAt'] as String?;
        final itemCreatedAt = itemCreatedStr != null
            ? DateTime.tryParse(itemCreatedStr) ?? DateTime.now()
            : DateTime.now();

        items.add(
          TodoItem(
            id: m['id'] as String,
            listId: listId,
            title: (m['title'] as String?) ?? '',
            isCompleted: (m['isCompleted'] as bool?) ?? false,
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
        final role = CollaboratorRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => CollaboratorRole.member,
        );
        members.add(
          Collaborator(
            id: (m['userId'] as String?) ?? (m['id'] as String? ?? ''),
            name:
                (m['displayName'] as String?) ??
                (m['email'] as String?) ??
                'Colaborador',
            email: (m['email'] as String?) ?? '',
            isOwner: isOwner,
            role: role,
          ),
        );
      }

      final shoppingList = ShoppingList(
        id: listId,
        name: listName,
        isSynced: true,
        isStarred: rawList['isStarred'] as bool? ?? false,
        isShared: true,
        hasInvite: true,
        position: (rawList['position'] as num?)?.toInt() ?? 0,
        createdAt: listCreatedAt,
        items: items,
        collaborators: members,
      );

      return JoinResult(list: shoppingList, alreadyMember: alreadyMember);
    }

    _handleError(response);
  }

  Future<List<Collaborator>> getMembers(String listId) async {
    final response = await _apiClient.get('/lists/$listId/members');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final roleStr = m['role'] as String? ?? 'member';
        final role = CollaboratorRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => CollaboratorRole.member,
        );
        return Collaborator(
          id: m['userId'] as String,
          name: m['displayName'] as String? ?? 'Colaborador',
          email: m['email'] as String? ?? '',
          role: role,
          isOwner: roleStr == 'owner',
        );
      }).toList();
    }
    _handleError(response);
  }

  Future<void> leaveList(String listId) async {
    final response = await _apiClient.delete('/lists/$listId/members/me');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError(response);
    }
  }

  Future<void> removeCollaborator(String listId, String userId) async {
    final response = await _apiClient.delete('/lists/$listId/members/$userId');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError(response);
    }
  }

  Future<void> updateCollaboratorRole(
    String listId,
    String userId,
    CollaboratorRole role,
  ) async {
    final roleName = role == CollaboratorRole.admin ? 'admin' : 'member';
    final response = await _apiClient.patch(
      '/lists/$listId/members/$userId',
      body: {'role': roleName},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError(response);
    }
  }

  Never _handleError(dynamic response) {
    ApiException apiException;
    if (response is ApiException) {
      apiException = response;
    } else {
      apiException = _apiClient.parseError(response);
    }
    _throwDomainException(apiException.errorCode, apiException.message);
  }

  Never _throwDomainException(String? errorCode, String? message) {
    final code = errorCode ?? '';
    final msg = message ?? '';
    if (code == 'MEMBER_LIMIT_REACHED' ||
        msg.contains('LIST_MEMBER_LIMIT_REACHED') ||
        msg.contains('MEMBER_LIMIT_REACHED')) {
      throw const ListMemberLimitReachedException();
    }
    if (code == 'INVITE_EXPIRED' || msg.contains('INVITE_EXPIRED')) {
      throw const InviteExpiredException();
    }
    if (code == 'INVITE_REVOKED' ||
        code == 'INVITE_NOT_FOUND' ||
        code == 'INVALID_INVITE' ||
        msg.contains('INVALID_INVITE')) {
      throw const InvalidInviteException();
    }
    if (code == 'UNAUTHENTICATED' || msg.contains('UNAUTHENTICATED')) {
      throw const UnauthenticatedJoinException();
    }
    throw InvalidInviteException(msg.isNotEmpty ? msg : 'Error de invitación');
  }
}

final apiCollaborationRepositoryProvider = Provider<ApiCollaborationRepository>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    final authSession = ref.watch(authSessionServiceProvider);
    return ApiCollaborationRepository(
      apiClient: apiClient,
      authSession: authSession,
    );
  },
);
