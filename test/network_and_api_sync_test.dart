import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:listix/src/core/config/api_config.dart';
import 'package:listix/src/core/network/api_client.dart';
import 'package:listix/src/core/network/api_exception.dart';
import 'package:listix/src/core/network/auth_session_service.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/collaboration/data/repositories/api_collaboration_repository.dart';
import 'package:listix/src/features/collaboration/domain/entities/collaboration_exceptions.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/domain/repositories/lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/share_list_sheet.dart';
import 'package:listix/src/features/lists/presentation/services/share_service.dart';
import 'package:listix/src/features/sync/data/api_sync_service.dart';
import 'package:listix/src/features/sync/domain/pending_operation.dart';
import 'package:listix/src/features/sync/domain/sync_status.dart';
import 'package:listix/src/features/sync/presentation/sync_controller.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    _data.clear();
  }
}

class FakeHttpClient extends http.BaseClient {
  Future<http.Response> Function(http.BaseRequest request) handler;

  FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

class FakeListsRepositoryForSync implements ListsRepository {
  List<ShoppingList> lists = [];
  List<PendingOperation> pending = [];
  List<String> deletedListIds = [];
  List<String> removedPendingIds = [];

  @override
  Future<List<ShoppingList>> getLists() async => lists;

  @override
  Future<ShoppingList?> getListById(String id) async =>
      lists.where((l) => l.id == id).firstOrNull;

  @override
  Future<ShoppingList> createList(String name, {int? color}) async {
    final l = ShoppingList(id: 'new_id', name: name, createdAt: DateTime.now());
    lists.add(l);
    return l;
  }

  @override
  Future<ShoppingList> joinSharedList(
    String listId,
    String name, {
    String? ownerName,
    String? ownerEmail,
  }) async {
    final l = ShoppingList(
      id: listId,
      name: name,
      createdAt: DateTime.now(),
      isShared: true,
    );
    lists.add(l);
    return l;
  }

  @override
  Future<ShoppingList> updateListName(
    String id,
    String newName, {
    int? color,
  }) async => throw UnimplementedError();

  @override
  Future<void> archiveList(String listId) async {}

  @override
  Future<void> unarchiveList(String listId) async {}

  @override
  Future<TodoItem> updateItemTitle(
    String listId,
    String itemId,
    String newTitle,
  ) async => throw UnimplementedError();

  @override
  Future<void> applyRemoteItemUpdate(
    String listId,
    String itemId,
    String newTitle,
  ) async {}

  @override
  Future<void> deleteList(String id) async {
    deletedListIds.add(id);
    lists.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> restoreList(ShoppingList list) async {}

  @override
  Future<void> toggleListStar(String listId) async {}

  @override
  Future<void> reorderLists(List<String> orderedListIds) async {}

  @override
  Future<TodoItem> addItem(String listId, String title, {String? id}) async =>
      TodoItem(
        id: id ?? 'item_1',
        listId: listId,
        title: title,
        createdAt: DateTime.now(),
      );

  @override
  Future<TodoItem> toggleItemCompletion(String listId, String itemId) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteItem(String listId, String itemId) async {}

  @override
  Future<void> restoreItem(TodoItem item) async {}

  @override
  Future<void> reorderItems(String listId, List<String> orderedItemIds) async {}

  @override
  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  }) async {}

  @override
  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {}

  @override
  Future<void> applyRemoteCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {}

  @override
  Future<void> removeCollaborator(String listId, String collaboratorId) async {}

  @override
  Future<void> syncList(String listId) async {}

  @override
  Future<void> setListShared(
    String listId,
    bool isShared, {
    bool? hasInvite,
  }) async {
    final idx = lists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      lists[idx] = lists[idx].copyWith(
        isShared: isShared,
        hasInvite: hasInvite ?? true,
      );
    }
  }

  @override
  Future<void> markListInviteCreated(String listId) async {}

  @override
  Future<void> applyRemoteItem(TodoItem item) async {}

  @override
  Future<void> applyRemoteItemToggle(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {}

  @override
  Future<void> applyRemoteItemDelete(String listId, String itemId) async {}

  @override
  Future<void> applyRemoteCollaborator(
    String listId,
    Collaborator collaborator,
  ) async {}

  @override
  Future<void> applyRemoteCollaboratorRemove(
    String listId,
    String collaboratorId,
  ) async {}

  @override
  Future<void> saveRemoteList(ShoppingList list) async {
    final idx = lists.indexWhere((l) => l.id == list.id);
    if (idx != -1) {
      lists[idx] = list;
    } else {
      lists.add(list);
    }
  }

  @override
  Future<List<PendingOperation>> getPendingOperations({String? listId}) async =>
      pending;

  @override
  Future<void> removePendingOperation(String id) async {
    removedPendingIds.add(id);
    pending.removeWhere((op) => op.id == id);
  }

  @override
  Future<void> clearPendingOperationsForList(String listId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Network and API Sync Tests Suite', () {
    setUpAll(() async {
      ApiConfig.testBaseUrl = 'https://listix-worker.onrender.com';
      sqfliteFfiInit();
      try {
        if (databaseFactory != databaseFactoryFfi) {
          databaseFactory = databaseFactoryFfi;
        }
      } catch (_) {
        databaseFactory = databaseFactoryFfi;
      }
      AppDatabase.overrideDbPath = inMemoryDatabasePath;
      await AppDatabase.instance.database;
    });

    tearDownAll(() {
      ApiConfig.testBaseUrl = null;
      AuthSessionService.instance.testInitialized = false;
    });

    group('ApiConfig Tests', () {
    test('values and getters', () {
      expect(ApiConfig.apiBaseUrl, isNotNull);
      expect(ApiConfig.effectiveBaseUrl, isNotEmpty);
      expect(ApiConfig.normalizedBaseUrl, isNotEmpty);
      expect(ApiConfig.restBaseUrl, contains('/api/v1'));
      expect(ApiConfig.realtimeNamespace, '/realtime');
      expect(ApiConfig.isConfigured, isTrue);
      expect(
        ApiConfig.normalizeUrl('http://localhost:3000/'),
        'http://localhost:3000',
      );
    });
  });

  group('ApiException Tests', () {
    test('properties and toString', () {
      const ex1 = ApiException(
        statusCode: 404,
        errorCode: 'NOT_FOUND',
        message: 'Resource not found',
      );
      expect(ex1.statusCode, 404);
      expect(ex1.errorCode, 'NOT_FOUND');
      expect(ex1.message, 'Resource not found');
      expect(ex1.toString(), contains('NOT_FOUND'));

      const ex2 = ApiException(statusCode: 500, message: 'Server error');
      expect(ex2.errorCode, isNull);
      expect(ex2.toString(), contains('500'));
    });
  });

  group('AuthSessionService Tests', () {
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
    });

    test('authenticateAnonymously success', () async {
      final fakeHttp = FakeHttpClient((request) async {
        expect(request.url.path, '/api/v1/auth/anonymous');
        return http.Response(
          jsonEncode({
            'userId': 'user_123',
            'accessToken': 'token_abc',
            'accessTokenExpiresIn': 900,
            'refreshToken': 'refresh_xyz',
            'refreshTokenExpiresAt': '2026-11-01T12:00:00.000Z',
          }),
          201,
        );
      });

      final auth = AuthSessionService(
        storage: storage,
        httpClient: fakeHttp,
        initialized: true,
      );
      await auth.authenticateAnonymously();

      expect(auth.currentUserId, 'user_123');
      expect(await auth.getAccessToken(), 'token_abc');
      expect(await auth.getUserId(), 'user_123');
      expect(await storage.read(key: 'listix_access_token'), 'token_abc');
      expect(await storage.read(key: 'listix_refresh_token'), 'refresh_xyz');
    });

    test('authenticateAnonymously failure throws ApiException', () async {
      final fakeHttp = FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({'errorCode': 'ERROR', 'message': 'Failed'}),
          400,
        );
      });

      final auth = AuthSessionService(
        storage: storage,
        httpClient: fakeHttp,
        initialized: true,
      );
      expect(
        () => auth.authenticateAnonymously(),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'authenticateAnonymously plain text failure throws ApiException',
      () async {
        final fakeHttp = FakeHttpClient((request) async {
          return http.Response(
            'Internal Error',
            500,
            reasonPhrase: 'Server Error',
          );
        });

        final auth = AuthSessionService(
          storage: storage,
          httpClient: fakeHttp,
          initialized: true,
        );
        expect(
          () => auth.authenticateAnonymously(),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('initialize loads from storage and refreshes if expiring', () async {
      await storage.write(key: 'listix_access_token', value: 'old_token');
      await storage.write(key: 'listix_refresh_token', value: 'old_refresh');
      await storage.write(key: 'listix_user_id', value: 'saved_user');
      await storage.write(
        key: 'listix_access_token_expires_at',
        value: DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      );

      final fakeHttp = FakeHttpClient((request) async {
        expect(request.url.path, '/api/v1/auth/refresh');
        return http.Response(
          jsonEncode({
            'userId': 'saved_user',
            'accessToken': 'new_token',
            'accessTokenExpiresIn': 900,
            'refreshToken': 'new_refresh',
          }),
          200,
        );
      });

      final auth = AuthSessionService(
        storage: storage,
        httpClient: fakeHttp,
        initialized: true,
      );
      await auth.initialize();

      expect(await auth.getAccessToken(), 'new_token');
      expect(await auth.getUserId(), 'saved_user');
    });

    test(
      'refreshTokens when invalid refresh token clears and re-authenticates',
      () async {
        await storage.write(key: 'listix_refresh_token', value: 'bad_refresh');

        var callCount = 0;
        final fakeHttp = FakeHttpClient((request) async {
          callCount++;
          if (request.url.path == '/api/v1/auth/refresh') {
            return http.Response(
              jsonEncode({'errorCode': 'INVALID_TOKEN'}),
              401,
            );
          }
          if (request.url.path == '/api/v1/auth/anonymous') {
            return http.Response(
              jsonEncode({
                'userId': 'fresh_user',
                'accessToken': 'fresh_token',
                'refreshToken': 'fresh_refresh',
              }),
              201,
            );
          }
          return http.Response('not found', 404);
        });

        final auth = AuthSessionService(
          storage: storage,
          httpClient: fakeHttp,
          initialized: true,
        );
        final res = await auth.refreshTokens();

        expect(res, isTrue);
        expect(callCount, 2);
        expect(await auth.getAccessToken(), 'fresh_token');
      },
    );

    test('refreshTokens throws on 500 error', () async {
      await storage.write(key: 'listix_refresh_token', value: 'valid_refresh');
      final fakeHttp = FakeHttpClient((request) async {
        return http.Response('Server Error', 500);
      });

      final auth = AuthSessionService(
        storage: storage,
        httpClient: fakeHttp,
        initialized: true,
      );
      expect(() => auth.refreshTokens(), throwsA(isA<ApiException>()));
    });

    test('clearSession resets memory and storage', () async {
      await storage.write(key: 'listix_access_token', value: 'token');
      final auth = AuthSessionService(storage: storage, initialized: true);
      await auth.clearSession();

      expect(await storage.read(key: 'listix_access_token'), isNull);
      expect(auth.currentUserId, isNull);
    });

    test('initialize when not configured does nothing', () async {
      final unconfigured = AuthSessionService(isConfigured: () => false);
      await unconfigured.initialize();
      expect(unconfigured.isReady, isFalse);
    });

    test(
      'initialize when storage is empty authenticates anonymously',
      () async {
        final fakeHttp = FakeHttpClient((request) async {
          return http.Response(
            jsonEncode({
              'userId': 'user_new',
              'accessToken': 'tok_new',
              'accessTokenExpiresIn': 900,
              'refreshToken': 'ref_new',
            }),
            201,
          );
        });
        final auth = AuthSessionService(storage: storage, httpClient: fakeHttp);
        await auth.initialize();
        expect(auth.isReady, isTrue);
        expect(auth.currentUserId, 'user_new');
      },
    );

    test(
      'getAccessToken when token is null authenticates anonymously',
      () async {
        final fakeHttp = FakeHttpClient((request) async {
          return http.Response(
            jsonEncode({
              'userId': 'user_anon',
              'accessToken': 'anon_token',
              'accessTokenExpiresIn': 900,
              'refreshToken': 'anon_ref',
            }),
            201,
          );
        });
        final auth = AuthSessionService(
          storage: storage,
          httpClient: fakeHttp,
          initialized: true,
        );
        final token = await auth.getAccessToken();
        expect(token, 'anon_token');
      },
    );

    test('getAccessToken refreshes when expiring soon', () async {
      await storage.write(key: 'listix_access_token', value: 'old_access');
      await storage.write(key: 'listix_refresh_token', value: 'good_refresh');
      await storage.write(
        key: 'listix_access_token_expires_at',
        value: DateTime.now()
            .add(const Duration(seconds: 10))
            .toIso8601String(),
      );
      final fakeHttp = FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'userId': 'u1',
            'accessToken': 'refreshed_access',
            'accessTokenExpiresIn': 900,
            'refreshToken': 'good_refresh_2',
          }),
          200,
        );
      });
      final auth = AuthSessionService(
        storage: storage,
        httpClient: fakeHttp,
        initialized: true,
      );
      final token = await auth.getAccessToken();
      expect(token, 'refreshed_access');
    });

    test('getUserId loads from storage or authenticates', () async {
      await storage.write(key: 'listix_user_id', value: 'stored_user_id');
      final auth1 = AuthSessionService(storage: storage, initialized: true);
      expect(await auth1.getUserId(), 'stored_user_id');

      final storage2 = FakeSecureStorage();
      final fakeHttp = FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'userId': 'anon_user_id',
            'accessToken': 'tok',
            'accessTokenExpiresIn': 900,
            'refreshToken': 'ref',
          }),
          201,
        );
      });
      final auth2 = AuthSessionService(
        storage: storage2,
        httpClient: fakeHttp,
        initialized: true,
      );
      expect(await auth2.getUserId(), 'anon_user_id');
    });

    test('parseErrorForTest fallback message', () {
      final auth = AuthSessionService();
      final err = auth.parseErrorForTest(http.Response('{}', 400));
      expect(err.statusCode, 400);
      expect(err.message, 'Request failed');
    });

    test('authSessionServiceProvider provides instance', () {
      final container = ProviderContainer();
      final auth = container.read(authSessionServiceProvider);
      expect(auth, isNotNull);
      container.dispose();
    });
  });

  group('ApiClient Tests', () {
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
    });

    test('get, post, put, patch, delete methods and query params', () async {
      await storage.write(key: 'listix_access_token', value: 'bearer_token');
      final auth = AuthSessionService(storage: storage, initialized: true);

      final methodsCalled = <String>[];
      final fakeHttp = FakeHttpClient((request) async {
        methodsCalled.add(request.method);
        expect(request.headers['Authorization'], 'Bearer bearer_token');
        return http.Response('{"ok": true}', 200);
      });

      final client = ApiClient(httpClient: fakeHttp, authSession: auth);

      final resGet = await client.get('/lists', queryParameters: {'q': 'test'});
      expect(resGet.statusCode, 200);

      final resPost = await client.post('/lists', body: {'name': 'New List'});
      expect(resPost.statusCode, 200);

      final resPut = await client.put('/lists/1', body: '{"name": "Updated"}');
      expect(resPut.statusCode, 200);

      final resPatch = await client.patch(
        '/lists/1/members/u1',
        body: {'role': 'admin'},
      );
      expect(resPatch.statusCode, 200);

      final resDelete = await client.delete(
        '/lists/1',
        queryParameters: {'force': true},
      );
      expect(resDelete.statusCode, 200);

      expect(methodsCalled, ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']);
    });

    test('401 response triggers refresh and retries once', () async {
      await storage.write(key: 'listix_access_token', value: 'expired_token');
      await storage.write(key: 'listix_refresh_token', value: 'valid_refresh');

      var attempts = 0;
      final fakeHttp = FakeHttpClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          return http.Response(
            jsonEncode({
              'userId': 'user_1',
              'accessToken': 'fresh_access_token',
              'refreshToken': 'new_refresh',
            }),
            200,
          );
        }

        attempts++;
        if (attempts == 1) {
          expect(request.headers['Authorization'], 'Bearer expired_token');
          return http.Response('{"message": "Unauthorized"}', 401);
        } else {
          expect(request.headers['Authorization'], 'Bearer fresh_access_token');
          return http.Response('{"success": true}', 200);
        }
      });

      final auth = AuthSessionService(
        storage: storage,
        httpClient: fakeHttp,
        initialized: true,
      );
      final client = ApiClient(httpClient: fakeHttp, authSession: auth);

      final response = await client.get('/protected');
      expect(response.statusCode, 200);
      expect(attempts, 2);
    });

    test('parseError extracts JSON message or falls back to reasonPhrase', () {
      final client = ApiClient();
      final err1 = client.parseError(
        http.Response(
          jsonEncode({'errorCode': 'ERR', 'message': 'Custom error'}),
          400,
        ),
      );
      expect(err1.statusCode, 400);
      expect(err1.errorCode, 'ERR');
      expect(err1.message, 'Custom error');

      final err2 = client.parseError(
        http.Response(
          'plain text error',
          503,
          reasonPhrase: 'Service Unavailable',
        ),
      );
      expect(err2.statusCode, 503);
      expect(err2.message, 'Service Unavailable');
    });

    test('request unsupported method throws ArgumentError', () {
      final fakeHttp = FakeHttpClient(
        (request) async => http.Response('ok', 200),
      );
      final client = ApiClient(httpClient: fakeHttp);
      expect(() => client.request('OPTIONS', '/path'), throwsArgumentError);
    });

    test('parseError edge cases without reasonPhrase or message', () {
      final client = ApiClient();
      final err1 = client.parseError(http.Response('{}', 400));
      expect(err1.statusCode, 400);
      expect(err1.message, 'Request failed with status 400');

      final err2 = client.parseError(http.Response('not json', 500));
      expect(err2.statusCode, 500);
      expect(err2.message, 'Request failed with status 500');
    });

    test('apiClientProvider provides instance', () {
      final container = ProviderContainer();
      final client = container.read(apiClientProvider);
      expect(client, isNotNull);
      container.dispose();
    });
  });

  group('ApiCollaborationRepository Tests', () {
    late FakeSecureStorage storage;
    late AuthSessionService auth;

    setUp(() async {
      storage = FakeSecureStorage();
      await storage.write(key: 'listix_access_token', value: 'tok');
      auth = AuthSessionService(storage: storage, initialized: true);
    });

    test('createInviteLink success and failure', () async {
      await storage.write(key: 'listix_access_token', value: 'tok');
      final auth = AuthSessionService(storage: storage, initialized: true);

      var shouldFail = false;
      final fakeHttp = FakeHttpClient((request) async {
        if (shouldFail) {
          return http.Response(
            jsonEncode({'errorCode': 'UNAUTHENTICATED', 'message': 'No auth'}),
            401,
          );
        }
        return http.Response(
          jsonEncode({
            'inviteId': 'inv_1',
            'inviteUrl': 'https://api.listix.app/join/CODE1234',
          }),
          201,
        );
      });

      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final repo = ApiCollaborationRepository(
        apiClient: client,
        authSession: auth,
      );

      final link = await repo.createInviteLink(listId: 'list_1');
      expect(link, 'https://api.listix.app/join/CODE1234');

      shouldFail = true;
      expect(
        () => repo.createInviteLink(listId: 'list_1'),
        throwsA(isA<UnauthenticatedJoinException>()),
      );
    });

    test('validateInvite handling', () async {
      final auth = AuthSessionService(storage: storage, initialized: true);
      var responseType = 'valid';

      final fakeHttp = FakeHttpClient((request) async {
        if (responseType == 'valid') {
          return http.Response(
            jsonEncode({
              'valid': true,
              'listName': 'Groceries',
              'memberCount': 2,
              'maxMembers': 5,
            }),
            200,
          );
        }
        if (responseType == 'member_limit') {
          return http.Response(
            jsonEncode({'valid': false, 'errorCode': 'MEMBER_LIMIT_REACHED'}),
            200,
          );
        }
        if (responseType == 'expired') {
          return http.Response(
            jsonEncode({'valid': false, 'errorCode': 'INVITE_EXPIRED'}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'valid': false, 'errorCode': 'INVITE_REVOKED'}),
          200,
        );
      });

      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final repo = ApiCollaborationRepository(
        apiClient: client,
        authSession: auth,
      );

      final data = await repo.validateInvite('CODE1234');
      expect(data['valid'], isTrue);

      responseType = 'member_limit';
      expect(
        () => repo.validateInvite('CODE1234'),
        throwsA(isA<ListMemberLimitReachedException>()),
      );

      responseType = 'expired';
      expect(
        () => repo.validateInvite('CODE1234'),
        throwsA(isA<InviteExpiredException>()),
      );

      responseType = 'revoked';
      expect(
        () => repo.validateInvite('CODE1234'),
        throwsA(isA<InvalidInviteException>()),
      );

      expect(
        () => repo.validateInvite(''),
        throwsA(isA<InvalidInviteException>()),
      );
    });

    test('joinListByToken parses snapshot and builds ShoppingList', () async {
      await storage.write(key: 'listix_access_token', value: 'tok');
      final auth = AuthSessionService(storage: storage, initialized: true);

      final fakeHttp = FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'alreadyMember': false,
            'list': {
              'id': 'list_abc',
              'name': 'Shared Groceries',
              'isStarred': true,
              'position': 2,
              'createdAt': '2026-10-18T10:00:00.000Z',
            },
            'items': [
              {
                'id': 'item_1',
                'title': 'Milk',
                'isCompleted': false,
                'position': 0,
                'createdAt': '2026-10-18T10:01:00.000Z',
              },
            ],
            'members': [
              {
                'userId': 'user_owner',
                'role': 'owner',
                'displayName': 'Owner User',
                'email': 'owner@example.com',
              },
              {
                'userId': 'user_collab',
                'role': 'member',
                'displayName': 'Collab User',
                'email': 'collab@example.com',
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final repo = ApiCollaborationRepository(
        apiClient: client,
        authSession: auth,
      );

      final result = await repo.joinListByToken(
        tokenOrUrl: 'CODE1234',
        displayName: 'Ana',
      );
      expect(result.alreadyMember, isFalse);
      expect(result.list.id, 'list_abc');
      expect(result.list.name, 'Shared Groceries');
      expect(result.list.items.length, 1);
      expect(result.list.collaborators.length, 2);
      expect(result.list.collaborators[0].isOwner, isTrue);
      expect(result.list.collaborators[1].isOwner, isFalse);
    });

    test(
      'getMembers, leaveList, removeCollaborator, updateCollaboratorRole',
      () async {
        await storage.write(key: 'listix_access_token', value: 'tok');
        final auth = AuthSessionService(storage: storage, initialized: true);

        final fakeHttp = FakeHttpClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.contains('/members')) {
            return http.Response(
              jsonEncode([
                {
                  'userId': 'u1',
                  'role': 'owner',
                  'displayName': 'Alice',
                  'email': 'alice@example.com',
                },
              ]),
              200,
            );
          }
          if (request.method == 'DELETE') {
            return http.Response('', 204);
          }
          if (request.method == 'PATCH') {
            return http.Response(
              jsonEncode({
                'userId': 'u1',
                'role': 'admin',
                'displayName': 'Alice',
              }),
              200,
            );
          }
          return http.Response('error', 400);
        });

        final client = ApiClient(httpClient: fakeHttp, authSession: auth);
        final repo = ApiCollaborationRepository(
          apiClient: client,
          authSession: auth,
        );

        final members = await repo.getMembers('list_1');
        expect(members.length, 1);
        expect(members[0].name, 'Alice');

        await repo.leaveList('list_1');
        await repo.removeCollaborator('list_1', 'u1');
        await repo.updateCollaboratorRole(
          'list_1',
          'u1',
          CollaboratorRole.admin,
        );
        await repo.updateCollaboratorRole(
          'list_1',
          'u1',
          CollaboratorRole.member,
        );
      },
    );

    test('default constructor creates instance', () {
      final repo = ApiCollaborationRepository();
      expect(repo, isNotNull);
    });

    test('validateInvite error response throws domain exception', () async {
      final fakeHttp = FakeHttpClient(
        (request) async => http.Response('Server Error', 500),
      );
      final client = ApiClient(httpClient: fakeHttp);
      final repo = ApiCollaborationRepository(
        apiClient: client,
        authSession: auth,
      );
      expect(
        () => repo.validateInvite('CODE1234'),
        throwsA(isA<InvalidInviteException>()),
      );
    });

    test('joinListByToken edge cases and fallbacks', () async {
      final fakeHttp = FakeHttpClient((request) async {
        final req = request as http.Request;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['email'], 'ana@example.com');
        return http.Response(
          jsonEncode({
            'alreadyMember': true,
            'list': {'id': 'list_xyz', 'name': 'Edge List'},
            'items': [
              {'id': 'item_x', 'title': 'No Date Item'},
            ],
            'members': [
              {
                'userId': 'u_guest',
                'role': 'guest_role',
                'email': 'guest@example.com',
              },
            ],
          }),
          200,
        );
      });
      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final repo = ApiCollaborationRepository(
        apiClient: client,
        authSession: auth,
      );
      final result = await repo.joinListByToken(
        tokenOrUrl: 'CODE1234',
        displayName: 'Ana',
        email: 'ana@example.com',
      );
      expect(result.alreadyMember, isTrue);
      expect(result.list.items.first.title, 'No Date Item');
      expect(result.list.collaborators.first.name, 'guest@example.com');
      expect(result.list.collaborators.first.role, CollaboratorRole.member);
    });

    test('collaboration endpoints error handling', () async {
      final fakeHttp = FakeHttpClient((request) async {
        if (request.url.path.contains('/join')) {
          return http.Response(
            jsonEncode({
              'errorCode': 'CUSTOM_ERROR',
              'message': 'Custom error',
            }),
            400,
          );
        }
        if (request.url.path.endsWith('/members')) {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {'userId': 'u2', 'role': 'unknown_role', 'displayName': 'Bob'},
              ]),
              200,
            );
          }
        }
        return http.Response('Server Error', 500);
      });
      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final repo = ApiCollaborationRepository(
        apiClient: client,
        authSession: auth,
      );

      expect(
        () => repo.joinListByToken(tokenOrUrl: 'CODE1234'),
        throwsA(isA<InvalidInviteException>()),
      );

      final members = await repo.getMembers('list_1');
      expect(members.first.role, CollaboratorRole.member);

      final failingHttp = FakeHttpClient(
        (request) async => http.Response('Error', 500),
      );
      final failClient = ApiClient(httpClient: failingHttp, authSession: auth);
      final failRepo = ApiCollaborationRepository(
        apiClient: failClient,
        authSession: auth,
      );

      expect(
        () => failRepo.getMembers('list_1'),
        throwsA(isA<InvalidInviteException>()),
      );
      expect(
        () => failRepo.leaveList('list_1'),
        throwsA(isA<InvalidInviteException>()),
      );
      expect(
        () => failRepo.removeCollaborator('list_1', 'u1'),
        throwsA(isA<InvalidInviteException>()),
      );
      expect(
        () => failRepo.updateCollaboratorRole(
          'list_1',
          'u1',
          CollaboratorRole.admin,
        ),
        throwsA(isA<InvalidInviteException>()),
      );
    });

    test('apiCollaborationRepositoryProvider provides instance', () {
      final container = ProviderContainer();
      final repo = container.read(apiCollaborationRepositoryProvider);
      expect(repo, isNotNull);
      container.dispose();
    });
  });

  group('ApiSyncService Tests', () {
    late FakeSecureStorage storage;
    late FakeListsRepositoryForSync listsRepo;

    setUp(() {
      storage = FakeSecureStorage();
      listsRepo = FakeListsRepositoryForSync();
    });

    test('syncPendingOperations processes pending lists and items', () async {
      await storage.write(key: 'listix_access_token', value: 'token');
      final auth = AuthSessionService(storage: storage, initialized: true);

      listsRepo.pending = [
        PendingOperation(
          id: 'op_1',
          listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          entityType: PendingEntityType.list,
          opType: PendingOpType.upsert,
          entityId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          payload: {'name': 'Synced List', 'is_starred': 1, 'position': 0},
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        PendingOperation(
          id: 'op_2',
          listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          entityType: PendingEntityType.item,
          opType: PendingOpType.upsert,
          entityId: 'a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d',
          payload: {'title': 'New Item', 'is_completed': 0, 'position': 0},
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        PendingOperation(
          id: 'op_3',
          listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          entityType: PendingEntityType.item,
          opType: PendingOpType.delete,
          entityId: 'a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        PendingOperation(
          id: 'op_4',
          listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          entityType: PendingEntityType.list,
          opType: PendingOpType.delete,
          entityId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      listsRepo.lists = [
        ShoppingList(
          id: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          name: 'Synced List',
          isShared: true,
          hasInvite: true,
          createdAt: DateTime.now(),
        ),
      ];

      final fakeHttp = FakeHttpClient((request) async {
        if (request.method == 'PUT') {
          return http.Response('{"ok": true}', 200);
        }
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'list': {
                'id': 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
                'name': 'Synced List',
              },
              'items': [],
              'members': [],
            }),
            200,
          );
        }
        return http.Response('{"ok": true}', 200);
      });

      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final socket = socket_io.io(
        'http://localhost',
        socket_io.OptionBuilder().disableAutoConnect().build(),
      );

      final syncService = ApiSyncService(
        apiClient: client,
        authSession: auth,
        listsRepository: listsRepo,
        socket: socket,
      );

      await syncService.syncPendingOperations();

      expect(listsRepo.removedPendingIds.length, 4);
      expect(syncService.currentStatus, SyncStatus.synced);

      syncService.dispose();
    });

    test('pullRemoteList deletes list on 404/403', () async {
      await storage.write(key: 'listix_access_token', value: 'token');
      final auth = AuthSessionService(storage: storage, initialized: true);
      listsRepo.lists = [
        ShoppingList(
          id: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          name: 'Deleted List',
          createdAt: DateTime.now(),
        ),
      ];

      var remoteCallbackCalled = false;
      final fakeHttp = FakeHttpClient((request) async {
        return http.Response('{"message": "Not found"}', 404);
      });

      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final syncService = ApiSyncService(
        apiClient: client,
        authSession: auth,
        listsRepository: listsRepo,
        onRemoteChangeApplied: () {
          remoteCallbackCalled = true;
        },
      );

      await syncService.pullRemoteList('c2b988f4-6f02-474c-83b5-31296bf3ee20');
      expect(
        listsRepo.deletedListIds,
        contains('c2b988f4-6f02-474c-83b5-31296bf3ee20'),
      );
      expect(remoteCallbackCalled, isTrue);

      syncService.dispose();
    });

    test('pullRemoteList saves remote snapshot into SQLite', () async {
      await storage.write(key: 'listix_access_token', value: 'token');
      final auth = AuthSessionService(storage: storage, initialized: true);

      var remoteCallbackCalled = false;
      final fakeHttp = FakeHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'list': {
              'id': 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
              'name': 'Synced Remote List',
              'isStarred': false,
              'position': 0,
              'createdAt': '2026-10-18T10:00:00.000Z',
            },
            'items': [
              {
                'id': 'item_1',
                'title': 'Apples',
                'isCompleted': true,
                'position': 0,
                'createdAt': '2026-10-18T10:05:00.000Z',
              },
            ],
            'members': [
              {
                'userId': 'u1',
                'role': 'owner',
                'displayName': 'Owner',
                'email': 'owner@example.com',
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final syncService = ApiSyncService(
        apiClient: client,
        authSession: auth,
        listsRepository: listsRepo,
        onRemoteChangeApplied: () {
          remoteCallbackCalled = true;
        },
      );

      await syncService.pullRemoteList('c2b988f4-6f02-474c-83b5-31296bf3ee20');
      expect(listsRepo.lists.length, 1);
      expect(listsRepo.lists.first.name, 'Synced Remote List');
      expect(listsRepo.lists.first.items.length, 1);
      expect(remoteCallbackCalled, isTrue);

      syncService.dispose();
    });

    test('setOfflineSimulation toggles and triggers sync', () async {
      final syncService = ApiSyncService(listsRepository: listsRepo);

      syncService.setOfflineSimulation(true);
      expect(syncService.isSimulatedOffline, isTrue);
      expect(syncService.currentStatus, SyncStatus.offline);

      syncService.setOfflineSimulation(false);
      expect(syncService.isSimulatedOffline, isFalse);

      syncService.dispose();
    });

    test('socket events wiring and list subscribe/unsubscribe', () async {
      await storage.write(key: 'listix_access_token', value: 'token');
      final fakeHttp = FakeHttpClient((request) async {
        if (request.url.path.contains('/auth/')) {
          return http.Response(
            jsonEncode({
              'userId': 'u1',
              'accessToken': 'fresh_tok',
              'refreshToken': 'fresh_ref',
              'accessTokenExpiresIn': 900,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'list': {
              'id': 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
              'name': 'Updated',
            },
            'items': [],
            'members': [],
          }),
          200,
        );
      });
      final auth = AuthSessionService(
        storage: storage,
        httpClient: fakeHttp,
        initialized: true,
      );
      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final socket = socket_io.io(
        'http://localhost',
        socket_io.OptionBuilder().disableAutoConnect().build(),
      );

      final syncService = ApiSyncService(
        apiClient: client,
        authSession: auth,
        listsRepository: listsRepo,
        socket: socket,
      );

      syncService.subscribeToList('c2b988f4-6f02-474c-83b5-31296bf3ee20');
      socket.onconnect('sock_1', null);
      expect(socket.connected, isTrue);

      syncService.subscribeToList('list_connected');
      syncService.unsubscribeFromList('list_connected');

      socket.onevent({
        'data': [
          'list.changed',
          {'listId': 'c2b988f4-6f02-474c-83b5-31296bf3ee20'},
        ],
      });

      socket.onevent({
        'data': [
          'session.error',
          {'errorCode': 'TOKEN_EXPIRED'},
        ],
      });

      await Future<void>.delayed(Duration.zero);
      syncService.dispose();
    });

    test(
      'syncPendingOperations handles 404 delete and error responses',
      () async {
        await storage.write(key: 'listix_access_token', value: 'token');
        final auth = AuthSessionService(storage: storage, initialized: true);

        listsRepo.pending = [
          PendingOperation(
            id: 'op_del_list_404',
            listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            entityType: PendingEntityType.list,
            opType: PendingOpType.delete,
            entityId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
        var fakeHttp = FakeHttpClient(
          (request) async => http.Response('{"message": "Not found"}', 404),
        );
        var client = ApiClient(httpClient: fakeHttp, authSession: auth);
        var syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );
        await syncService.syncPendingOperations();
        expect(listsRepo.removedPendingIds, contains('op_del_list_404'));
        syncService.dispose();

        listsRepo.pending = [
          PendingOperation(
            id: 'op_del_list_500',
            listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            entityType: PendingEntityType.list,
            opType: PendingOpType.delete,
            entityId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
        fakeHttp = FakeHttpClient(
          (request) async => http.Response('Server Error', 500),
        );
        client = ApiClient(httpClient: fakeHttp, authSession: auth);
        syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );
        await syncService.syncPendingOperations();
        expect(syncService.currentStatus, SyncStatus.pendingChanges);
        syncService.dispose();

        listsRepo.pending = [
          PendingOperation(
            id: 'op_upsert_list_500',
            listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            entityType: PendingEntityType.list,
            opType: PendingOpType.upsert,
            entityId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            payload: {'name': 'L'},
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
        syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );
        await syncService.syncPendingOperations();
        expect(syncService.currentStatus, SyncStatus.pendingChanges);
        syncService.dispose();

        listsRepo.pending = [
          PendingOperation(
            id: 'op_del_item_404',
            listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            entityType: PendingEntityType.item,
            opType: PendingOpType.delete,
            entityId: 'a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
        fakeHttp = FakeHttpClient(
          (request) async => http.Response('{"message": "Not found"}', 404),
        );
        client = ApiClient(httpClient: fakeHttp, authSession: auth);
        syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );
        await syncService.syncPendingOperations();
        expect(listsRepo.removedPendingIds, contains('op_del_item_404'));
        syncService.dispose();

        listsRepo.pending = [
          PendingOperation(
            id: 'op_del_item_500',
            listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            entityType: PendingEntityType.item,
            opType: PendingOpType.delete,
            entityId: 'a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
        fakeHttp = FakeHttpClient(
          (request) async => http.Response('Server Error', 500),
        );
        client = ApiClient(httpClient: fakeHttp, authSession: auth);
        syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );
        await syncService.syncPendingOperations();
        expect(syncService.currentStatus, SyncStatus.pendingChanges);
        syncService.dispose();

        listsRepo.pending = [
          PendingOperation(
            id: 'op_upsert_item_500',
            listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            entityType: PendingEntityType.item,
            opType: PendingOpType.upsert,
            entityId: 'a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d',
            payload: {'title': 'T'},
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
        syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );
        await syncService.syncPendingOperations();
        expect(syncService.currentStatus, SyncStatus.pendingChanges);
        syncService.dispose();
      },
    );

    test(
      'syncPendingOperations general exception sets pendingChanges',
      () async {
        final throwingRepo = FakeListsRepositoryForSync();
        final auth = AuthSessionService(storage: storage, initialized: true);
        final client = ApiClient(
          httpClient: FakeHttpClient((req) async => throw Exception('net')),
          authSession: auth,
        );
        final syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: throwingRepo,
        );
        throwingRepo.pending = [
          PendingOperation(
            id: 'op_err',
            listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            entityType: PendingEntityType.list,
            opType: PendingOpType.delete,
            entityId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
        await syncService.syncPendingOperations();
        expect(syncService.currentStatus, SyncStatus.pendingChanges);
        syncService.dispose();
      },
    );

    test(
      'pullRemoteList handles snapshots with missing dates and unknown member role',
      () async {
        await storage.write(key: 'listix_access_token', value: 'token');
        final auth = AuthSessionService(storage: storage, initialized: true);
        final fakeHttp = FakeHttpClient((request) async {
          return http.Response(
            jsonEncode({
              'list': {
                'id': 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
                'name': 'Fallback List',
              },
              'items': [
                {'id': 'item_1', 'title': 'No Date'},
              ],
              'members': [
                {
                  'userId': 'u_special',
                  'role': 'special_role',
                  'email': 'fallback@example.com',
                },
              ],
            }),
            200,
          );
        });
        final client = ApiClient(httpClient: fakeHttp, authSession: auth);
        final syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );
        await syncService.pullRemoteList(
          'c2b988f4-6f02-474c-83b5-31296bf3ee20',
        );
        expect(listsRepo.lists.first.items.first.title, 'No Date');
        expect(
          listsRepo.lists.first.collaborators.first.name,
          'fallback@example.com',
        );
        expect(
          listsRepo.lists.first.collaborators.first.role,
          CollaboratorRole.member,
        );
        syncService.dispose();
      },
    );

    test(
      'apiSyncServiceProvider onRemoteChangeApplied invokes manualSync',
      () async {
        await storage.write(key: 'listix_access_token', value: 'tok');
        final auth = AuthSessionService(storage: storage, initialized: true);
        final fakeHttp = FakeHttpClient((request) async {
          return http.Response(
            jsonEncode({
              'list': {
                'id': 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
                'name': 'Remote List',
              },
              'items': [],
              'members': [],
            }),
            200,
          );
        });
        final client = ApiClient(httpClient: fakeHttp, authSession: auth);
        final container = ProviderContainer(
          overrides: [
            listsRepositoryProvider.overrideWithValue(listsRepo),
            authSessionServiceProvider.overrideWithValue(auth),
            apiClientProvider.overrideWithValue(client),
          ],
        );
        container.read(listsControllerProvider.notifier);
        final syncService = container.read(apiSyncServiceProvider);
        await syncService.pullRemoteList(
          'c2b988f4-6f02-474c-83b5-31296bf3ee20',
        );
        await Future<void>.delayed(Duration.zero);
        container.dispose();
      },
    );

    test('apiSyncServiceProvider provides instance', () {
      final container = ProviderContainer(
        overrides: [listsRepositoryProvider.overrideWithValue(listsRepo)],
      );
      final service = container.read(apiSyncServiceProvider);
      expect(service, isNotNull);
      container.dispose();
    });
  });

  group('SyncController with ApiSyncService', () {
    test('lifecycle, offline toggle, and syncNow', () async {
      final listsRepo = FakeListsRepositoryForSync();
      final storage = FakeSecureStorage();
      await storage.write(key: 'listix_access_token', value: 'tok');
      final auth = AuthSessionService(storage: storage, initialized: true);

      final fakeHttp = FakeHttpClient((request) async {
        return http.Response('{"ok": true}', 200);
      });
      final client = ApiClient(httpClient: fakeHttp, authSession: auth);

      final syncService = ApiSyncService(
        apiClient: client,
        authSession: auth,
        listsRepository: listsRepo,
      );

      final container = ProviderContainer(
        overrides: [
          authSessionServiceProvider.overrideWithValue(auth),
          apiSyncServiceProvider.overrideWithValue(syncService),
          listsRepositoryProvider.overrideWithValue(listsRepo),
        ],
      );

      final controller = container.read(syncControllerProvider.notifier);
      expect(controller.isOffline, isFalse);

      controller.toggleOfflineMode();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isOffline, isTrue);

      controller.toggleOfflineMode();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isOffline, isFalse);

      final synced = await controller.syncNow();
      expect(synced, isTrue);

      container.dispose();
      syncService.dispose();
    });

    testWidgets('SyncController timer triggers periodic sync on resume', (
      tester,
    ) async {
      final listsRepo = FakeListsRepositoryForSync();
      final storage = FakeSecureStorage();
      await storage.write(key: 'listix_access_token', value: 'tok');
      final auth = AuthSessionService(storage: storage, initialized: true);
      final client = ApiClient(
        httpClient: FakeHttpClient(
          (req) async => http.Response('{"ok": true}', 200),
        ),
        authSession: auth,
      );
      final syncService = ApiSyncService(
        apiClient: client,
        authSession: auth,
        listsRepository: listsRepo,
      );

      final container = ProviderContainer(
        overrides: [
          authSessionServiceProvider.overrideWithValue(auth),
          apiSyncServiceProvider.overrideWithValue(syncService),
          listsRepositoryProvider.overrideWithValue(listsRepo),
        ],
      );

      container.read(syncControllerProvider.notifier);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 31));

      container.dispose();
      syncService.dispose();
    });
  });

  group('ListsController and ShareListSheet with Api Collaboration', () {
    testWidgets('ShareListSheet generates invite link via api', (tester) async {
      final listsRepo = FakeListsRepositoryForSync();
      final list = ShoppingList(
        id: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
        name: 'Shared Sheet List',
        isShared: true,
        createdAt: DateTime.now(),
      );
      listsRepo.lists = [list];

      final storage = FakeSecureStorage();
      await storage.write(key: 'listix_access_token', value: 'tok');
      final auth = AuthSessionService(storage: storage, initialized: true);

      final fakeHttp = FakeHttpClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('/invites')) {
          return http.Response(
            jsonEncode({'inviteUrl': 'https://api.listix.app/join/CODE1234'}),
            201,
          );
        }
        return http.Response('{"ok": true}', 200);
      });
      final client = ApiClient(httpClient: fakeHttp, authSession: auth);
      final collabRepo = ApiCollaborationRepository(
        apiClient: client,
        authSession: auth,
      );
      final fakeShare = ShareService(
        systemShare: (text, {subject, sharePositionOrigin}) async =>
            const ShareResult('success', ShareResultStatus.success),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsRepositoryProvider.overrideWithValue(listsRepo),
            authSessionServiceProvider.overrideWithValue(auth),
            apiCollaborationRepositoryProvider.overrideWithValue(collabRepo),
            shareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ShareListSheet(
                listId: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ShareListSheet), findsOneWidget);
      await tester.tap(find.byKey(const Key('share_invite_link_button')));
      await tester.pumpAndSettle();
    });

    test(
      'ListsController joinListByInviteToken, syncListOnShare, setListShared',
      () async {
        final listsRepo = FakeListsRepositoryForSync();
        listsRepo.lists = [
          ShoppingList(
            id: 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
            name: 'Joined List',
            isShared: true,
            hasInvite: true,
            createdAt: DateTime.now(),
          ),
        ];
        final storage = FakeSecureStorage();
        await storage.write(key: 'listix_access_token', value: 'tok');
        final auth = AuthSessionService(storage: storage, initialized: true);

        final fakeHttp = FakeHttpClient((request) async {
          if (request.method == 'POST' && request.url.path.contains('/join')) {
            return http.Response(
              jsonEncode({
                'alreadyMember': false,
                'list': {
                  'id': 'c2b988f4-6f02-474c-83b5-31296bf3ee20',
                  'name': 'Joined List',
                  'createdAt': '2026-10-18T10:00:00.000Z',
                },
                'items': [],
                'members': [],
              }),
              200,
            );
          }
          return http.Response('{"ok": true}', 200);
        });
        final client = ApiClient(httpClient: fakeHttp, authSession: auth);
        final collabRepo = ApiCollaborationRepository(
          apiClient: client,
          authSession: auth,
        );

        final syncService = ApiSyncService(
          apiClient: client,
          authSession: auth,
          listsRepository: listsRepo,
        );

        final container = ProviderContainer(
          overrides: [
            listsRepositoryProvider.overrideWithValue(listsRepo),
            authSessionServiceProvider.overrideWithValue(auth),
            apiCollaborationRepositoryProvider.overrideWithValue(collabRepo),
            apiSyncServiceProvider.overrideWithValue(syncService),
          ],
        );

        final controller = container.read(listsControllerProvider.notifier);

        final joined = await controller.joinListByInviteToken('CODE1234');
        expect(joined.id, 'c2b988f4-6f02-474c-83b5-31296bf3ee20');

        await controller.syncListOnShare(
          'c2b988f4-6f02-474c-83b5-31296bf3ee20',
        );
        await controller.setListShared(
          'c2b988f4-6f02-474c-83b5-31296bf3ee20',
          true,
        );

        container.dispose();
        syncService.dispose();
      },
    );
  });
});
}
