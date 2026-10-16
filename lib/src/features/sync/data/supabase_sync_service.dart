// coverage:ignore-file
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../lists/domain/entities/collaborator.dart';
import '../../lists/domain/entities/shopping_list.dart';
import '../../lists/domain/entities/todo_item.dart';
import '../../lists/domain/repositories/lists_repository.dart';
import '../domain/pending_operation.dart';
import '../domain/sync_status.dart';

/// Sync service that coordinates synchronization between local SQLite
/// and remote Supabase PostgreSQL with Realtime collaboration for shared lists.
class SupabaseSyncService {
  final SupabaseService _supabaseService;
  final ListsRepository _listsRepository;
  final VoidCallback? _onRemoteChangeApplied;

  bool _isSimulatedOffline = false;
  bool _syncInProgress = false;
  SyncStatus _currentStatus = SyncStatus.synced;
  final _statusController = StreamController<SyncStatus>.broadcast();
  final Map<String, RealtimeChannel> _listChannels = {};

  SupabaseSyncService({
    SupabaseService? supabaseService,
    required ListsRepository listsRepository,
    VoidCallback? onRemoteChangeApplied,
  }) : _supabaseService = supabaseService ?? SupabaseService.instance,
       _listsRepository = listsRepository,
       _onRemoteChangeApplied = onRemoteChangeApplied;

  SyncStatus get currentStatus => _currentStatus;
  Stream<SyncStatus> get statusStream => _statusController.stream;

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

  /// Processes local pending operations for shared lists and pushes them to Supabase.
  Future<void> syncPendingOperations() async {
    if (_isSimulatedOffline || !_supabaseService.isReady || _syncInProgress) {
      return;
    }

    _syncInProgress = true;
    _setStatus(SyncStatus.syncing);

    try {
      await _supabaseService.ensureAnonymousAuth();
      final pendingOps = (await _listsRepository.getPendingOperations())
          .where((operation) => _isUuid(operation.listId))
          .toList();

      for (final op in pendingOps) {
        try {
          await _executePendingOperation(op);
          await _listsRepository.removePendingOperation(op.id);
        } catch (e) {
          debugPrint('Error syncing pending operation ${op.id}: $e');
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

      _setStatus(SyncStatus.synced);
    } catch (e) {
      debugPrint('Sync failed: $e');
      _setStatus(SyncStatus.pendingChanges);
    } finally {
      _syncInProgress = false;
    }
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  Future<void> _executePendingOperation(PendingOperation op) async {
    final client = _supabaseService.client;
    if (client == null) return;
    final payload = op.payload;

    if (op.entityType == PendingEntityType.list) {
      if (op.opType == PendingOpType.delete) {
        await client.from('lists').delete().eq('id', op.entityId);
      } else if (payload != null) {
        final params = <String, dynamic>{
          'p_list_id': op.listId,
          'p_name': payload['name'],
        };
        if (payload.containsKey('is_starred')) {
          params['p_is_starred'] =
              payload['is_starred'] == 1 || payload['is_starred'] == true;
        }
        if (payload.containsKey('position')) {
          params['p_position'] = (payload['position'] as num).toInt();
        }
        await client.rpc('sync_shared_list', params: params);
      }
    } else if (op.entityType == PendingEntityType.item) {
      if (op.opType == PendingOpType.delete) {
        await client
            .from('list_items')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', op.entityId)
            .eq('list_id', op.listId);
      } else if (payload != null) {
        await client.from('list_items').upsert({
          'id': op.entityId,
          'list_id': op.listId,
          'title': payload['title'],
          'is_completed':
              (payload['is_completed'] == 1 || payload['is_completed'] == true),
          'position': payload['position'] ?? 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'deleted_at': null,
        });
      }
    }
  }

  /// Pulls the server's last-committed version into the local SQLite copy.
  Future<void> pullRemoteList(String listId) async {
    if (!_supabaseService.isReady || _isSimulatedOffline) return;
    final client = _supabaseService.client;
    if (client == null) return;

    try {
      // 1. Fetch remote list
      final listData = await client
          .from('lists')
          .select()
          .eq('id', listId)
          .maybeSingle();

      if (listData == null) {
        // List was deleted remotely
        await _listsRepository.deleteList(listId);
        _onRemoteChangeApplied?.call();
        return;
      }

      // 2. Fetch remote items
      final itemsData = await client
          .from('list_items')
          .select()
          .eq('list_id', listId)
          .isFilter('deleted_at', null)
          .order('position', ascending: true);

      // 3. Fetch remote members
      final membersData = await client
          .from('list_members')
          .select()
          .eq('list_id', listId);

      final remoteItems = (itemsData as List).map((row) {
        return TodoItem(
          id: row['id'] as String,
          listId: listId,
          title: row['title'] as String,
          isCompleted: row['is_completed'] as bool? ?? false,
          isSynced: true,
          position: (row['position'] as num?)?.toInt() ?? 0,
          createdAt:
              DateTime.tryParse(row['created_at']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();

      final remoteMembers = (membersData as List).map((row) {
        final roleStr = row['role'] as String? ?? 'member';
        final role = CollaboratorRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => CollaboratorRole.member,
        );
        return Collaborator(
          id: row['user_id'] as String,
          name: row['display_name'] as String? ?? 'Usuario',
          email: row['email'] as String? ?? '',
          role: role,
        );
      }).toList();

      final mergedList = ShoppingList(
        id: listId,
        name: listData['name'] as String,
        isShared: true,
        hasInvite: true,
        isStarred: listData['is_starred'] as bool? ?? false,
        position: (listData['position'] as num?)?.toInt() ?? 0,
        createdAt:
            DateTime.tryParse(listData['created_at']?.toString() ?? '') ??
            DateTime.now(),
        isSynced: true,
        items: remoteItems,
        collaborators: remoteMembers,
      );

      await _listsRepository.saveRemoteList(mergedList);
      _onRemoteChangeApplied?.call();
    } catch (e) {
      debugPrint('Error pulling remote list $listId: $e');
    }
  }

  /// Subscribes to Supabase Realtime postgres changes for a shared list.
  void subscribeToList(String listId) {
    if (!_supabaseService.isReady || _listChannels.containsKey(listId)) return;
    final client = _supabaseService.client;
    if (client == null) return;

    try {
      final channel = client.channel('public:lists:$listId');

      // Listen for list changes
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'lists',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: listId,
        ),
        callback: (payload) {
          pullRemoteList(listId);
        },
      );

      // Listen for item changes
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'list_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'list_id',
          value: listId,
        ),
        callback: (payload) {
          pullRemoteList(listId);
        },
      );

      // Listen for member changes
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'list_members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'list_id',
          value: listId,
        ),
        callback: (payload) {
          pullRemoteList(listId);
        },
      );

      channel.subscribe();
      _listChannels[listId] = channel;
    } catch (e) {
      debugPrint('Error subscribing to list $listId: $e');
    }
  }

  /// Unsubscribes from Realtime for a specific list.
  void unsubscribeFromList(String listId) {
    final channel = _listChannels.remove(listId);
    channel?.unsubscribe();
  }

  void dispose() {
    for (final channel in _listChannels.values) {
      channel.unsubscribe();
    }
    _listChannels.clear();
    _statusController.close();
  }
}
