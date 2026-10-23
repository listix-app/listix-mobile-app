import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_session_service.dart';
import '../../lists/domain/entities/collaborator.dart';
import '../../lists/domain/entities/shopping_list.dart';
import '../../lists/domain/entities/todo_item.dart';
import '../../lists/domain/repositories/lists_repository.dart';
import '../../lists/presentation/controllers/lists_controller.dart';
import '../domain/pending_operation.dart';
import '../domain/sync_status.dart';

class ApiSyncService {
  final ApiClient _apiClient;
  final AuthSessionService _authSession;
  final ListsRepository _listsRepository;
  final VoidCallback? _onRemoteChangeApplied;

  bool _isSimulatedOffline = false;
  bool _syncInProgress = false;
  SyncStatus _currentStatus = SyncStatus.synced;
  final _statusController = StreamController<SyncStatus>.broadcast();
  socket_io.Socket? _socket;
  final Set<String> _subscribedListIds = {};

  ApiSyncService({
    ApiClient? apiClient,
    AuthSessionService? authSession,
    required ListsRepository listsRepository,
    VoidCallback? onRemoteChangeApplied,
    socket_io.Socket? socket,
  }) : _apiClient = apiClient ?? ApiClient(),
       _authSession = authSession ?? AuthSessionService.instance,
       _listsRepository = listsRepository,
       _onRemoteChangeApplied = onRemoteChangeApplied,
       _socket = socket {
    if (_socket != null) {
      _wireSocketEvents(_socket!);
    }
  }

  SyncStatus get currentStatus => _currentStatus;
  Stream<SyncStatus> get statusStream => _statusController.stream;
  bool get isSimulatedOffline => _isSimulatedOffline;

  void setOfflineSimulation(bool isOffline) {
    _isSimulatedOffline = isOffline;
    if (isOffline) {
      _setStatus(SyncStatus.offline);
    } else {
      _setStatus(SyncStatus.synced);
      syncPendingOperations();
    }
  }

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> syncPendingOperations() async {
    if (_isSimulatedOffline) {
      return;
    }
    if (!_authSession.isReady) {
      await _authSession.ensureInitialized();
    }
    if (!_authSession.isReady || _syncInProgress) {
      return;
    }

    _syncInProgress = true;
    _setStatus(SyncStatus.syncing);

    try {
      await _authSession.getAccessToken();
      final allPending = await _listsRepository.getPendingOperations();
      for (final op in allPending) {
        if (!_isUuid(op.listId) ||
            (op.entityType == PendingEntityType.item &&
                !_isUuid(op.entityId))) {
          await _listsRepository.removePendingOperation(op.id);
        }
      }

      final pendingOps = (await _listsRepository.getPendingOperations())
          .where(
            (op) =>
                _isUuid(op.listId) &&
                (op.entityType != PendingEntityType.item ||
                    _isUuid(op.entityId)),
          )
          .toList();

      for (final op in pendingOps) {
        try {
          await _executePendingOperation(op);
          await _listsRepository.removePendingOperation(op.id);
        } catch (e) {
          _setStatus(SyncStatus.pendingChanges);
          return;
        }
      }

      final sharedLists = (await _listsRepository.getLists())
          .where((list) => list.canSyncAndShare && _isUuid(list.id))
          .toList();

      for (final list in sharedLists) {
        await pullRemoteList(list.id);
        subscribeToList(list.id);
      }

      await _ensureSocketConnected();
      _setStatus(SyncStatus.synced);
    } catch (e) {
      _setStatus(SyncStatus.pendingChanges);
    } finally {
      _syncInProgress = false;
    }
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  Future<void> _executePendingOperation(PendingOperation op) async {
    final payload = op.payload;

    if (op.entityType == PendingEntityType.list) {
      if (op.opType == PendingOpType.delete) {
        final response = await _apiClient.delete('/lists/${op.entityId}');
        if (response.statusCode >= 200 && response.statusCode < 300 ||
            response.statusCode == 404) {
          return;
        }
        throw _apiClient.parseError(response);
      } else if (payload != null) {
        final body = <String, dynamic>{
          'name': payload['name'] ?? 'Lista',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };
        if (payload.containsKey('is_starred')) {
          body['isStarred'] =
              payload['is_starred'] == 1 || payload['is_starred'] == true;
        }
        if (payload.containsKey('position')) {
          body['position'] = (payload['position'] as num).toInt();
        }

        final response = await _apiClient.put(
          '/lists/${op.listId}',
          body: body,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        throw _apiClient.parseError(response);
      }
    } else if (op.entityType == PendingEntityType.item) {
      if (op.opType == PendingOpType.delete) {
        final response = await _apiClient.delete(
          '/lists/${op.listId}/items/${op.entityId}',
          queryParameters: {
            'deletedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
        if (response.statusCode >= 200 && response.statusCode < 300 ||
            response.statusCode == 404) {
          return;
        }
        throw _apiClient.parseError(response);
      } else if (payload != null) {
        final body = <String, dynamic>{
          'title': payload['title'] ?? '',
          'isCompleted':
              payload['is_completed'] == 1 || payload['is_completed'] == true,
          'position': (payload['position'] as num?)?.toInt() ?? 0,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };

        final response = await _apiClient.put(
          '/lists/${op.listId}/items/${op.entityId}',
          body: body,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        throw _apiClient.parseError(response);
      }
    }
  }

  Future<void> pullRemoteList(String listId) async {
    if (_isSimulatedOffline) return;
    // coverage:ignore-start
    if (!_authSession.isReady) {
      await _authSession.ensureInitialized();
    }
    // coverage:ignore-end
    if (!_authSession.isReady) return;

    try {
      final response = await _apiClient.get('/lists/$listId');
      if (response.statusCode == 403 || response.statusCode == 404) {
        await _listsRepository.deleteList(listId);
        _onRemoteChangeApplied?.call();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['list'] as Map<String, dynamic>?;
      if (rawList == null) return;

      final rawItems = (data['items'] as List?) ?? [];
      final rawMembers = (data['members'] as List?) ?? [];

      final remoteItems = rawItems.map((item) {
        final m = Map<String, dynamic>.from(item as Map);
        return TodoItem(
          id: m['id'] as String,
          listId: listId,
          title: (m['title'] as String?) ?? '',
          isCompleted: (m['isCompleted'] as bool?) ?? false,
          isSynced: true,
          position: (m['position'] as num?)?.toInt() ?? 0,
          createdAt:
              DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();

      final remoteMembers = rawMembers.map((member) {
        final m = Map<String, dynamic>.from(member as Map);
        final roleStr = (m['role'] as String?) ?? 'member';
        final role = CollaboratorRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => CollaboratorRole.member,
        );
        return Collaborator(
          id: (m['userId'] as String?) ?? (m['id'] as String? ?? ''),
          name:
              (m['displayName'] as String?) ??
              (m['email'] as String?) ??
              'Usuario',
          email: (m['email'] as String?) ?? '',
          role: role,
          isOwner: roleStr == 'owner',
        );
      }).toList();

      final existingList = await _listsRepository.getListById(listId);
      final currentUserId = _authSession.currentUserId;
      final isOwner =
          remoteMembers.any(
            (m) =>
                currentUserId != null &&
                m.id == currentUserId &&
                m.role == CollaboratorRole.owner,
          ) ||
          (existingList?.isOwner ?? false);

      final mergedList = ShoppingList(
        id: listId,
        name: (rawList['name'] as String?) ?? 'Lista Compartida',
        isShared: true,
        hasInvite: true,
        isStarred: (rawList['isStarred'] as bool?) ?? false,
        position: (rawList['position'] as num?)?.toInt() ?? 0,
        createdAt:
            DateTime.tryParse(rawList['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        isSynced: true,
        isOwner: isOwner,
        items: remoteItems,
        collaborators: remoteMembers,
      );

      await _listsRepository.saveRemoteList(mergedList);
      _onRemoteChangeApplied?.call();
    } catch (_) {}
  }

  String _cleanToken(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  Future<void> _ensureSocketConnected() async {
    if (_socket != null && _socket!.connected) {
      return;
    }
    final rawToken = await _authSession.getAccessToken();
    if (rawToken == null) return;
    final token = _cleanToken(rawToken);

    if (_socket == null) {
      final options = socket_io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(15)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setTimeout(25000)
          .disableAutoConnect()
          .setAuth({'token': token})
          .build();
      _socket = socket_io.io(
        '${ApiConfig.normalizedBaseUrl}${ApiConfig.realtimeNamespace}',
        options,
      );
      _wireSocketEvents(_socket!);
    } else {
      _socket!.auth = {'token': token};
      _socket!.io.options?['auth'] = {'token': token};
    }
    _socket!.connect();
  }

  void _wireSocketEvents(socket_io.Socket socket) {
    socket.on('connect', (_) {
      for (final id in _subscribedListIds) {
        try {
          socket.emit('list:subscribe', {'listId': id});
          pullRemoteList(id);
        } catch (_) {}
      }
    });

    void handleListUpdated(dynamic data) {
      if (data is Map && data.containsKey('listId')) {
        pullRemoteList(data['listId'].toString());
      }
    }

    socket.on('list.changed', handleListUpdated);
    socket.on('list:update', handleListUpdated);

    socket.on('session.error', (_) async {
      await _authSession.refreshTokens();
      final newToken = await _authSession.getAccessToken();
      if (newToken != null && _socket != null) {
        final clean = _cleanToken(newToken);
        _socket!.auth = {'token': clean};
        _socket!.io.options?['auth'] = {'token': clean};
        _socket!.connect();
      }
    });
  }

  void subscribeToList(String listId) {
    _subscribedListIds.add(listId);
    if (_socket != null && _socket!.connected) {
      try {
        _socket!.emit('list:subscribe', {'listId': listId});
      } catch (_) {}
    } else {
      _ensureSocketConnected();
    }
  }

  void unsubscribeFromList(String listId) {
    _subscribedListIds.remove(listId);
    if (_socket != null && _socket!.connected) {
      try {
        _socket!.emit('list:unsubscribe', {'listId': listId});
      } catch (_) {}
    }
  }

  void dispose() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _subscribedListIds.clear();
    _statusController.close();
  }
}

final apiSyncServiceProvider = Provider<ApiSyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authSession = ref.watch(authSessionServiceProvider);
  final listsRepo = ref.watch(listsRepositoryProvider);
  final service = ApiSyncService(
    apiClient: apiClient,
    authSession: authSession,
    listsRepository: listsRepo,
    onRemoteChangeApplied: () {
      ref.read(listsControllerProvider.notifier).manualSync();
    },
  );
  ref.onDispose(service.dispose);
  return service;
});
