# Backend Integration

The Listix mobile app is **backend-agnostic**. It is offline-first: SQLite is the source of truth on-device, and a backend only synchronizes and shares data between devices. Any backend can be used by providing an adapter for it.

## Backend as an Adapter

- **Port (contract)**: the app core (domain, repositories, controllers, UI) depends only on an abstract sync contract expressed in domain terms (lists, items, collaborators, invites, pending operations, sync status, remote-change events). It knows nothing about REST paths, token formats, socket libraries or server-side storage.
- **Adapter (implementation)**: all transport, auth, serialization and realtime details live in a backend adapter in `lib/src/features/sync/data/`. `ApiSyncService` is the HTTP/Socket.IO adapter, and `MockBackendSyncService` is the fallback and test adapter.
- **Wiring**: the active adapter is selected in one Riverpod provider. Nothing else changes when it is swapped.
- **Mapping**: the adapter maps backend payloads to DTOs and then to domain entities, and translates backend errors into domain failures. Backend-specific shapes never leak past the adapter.

> Current state: `ApiSyncService` is a concrete class consumed by `sync_controller.dart` and `lists_controller.dart`. Extracting the abstract sync contract into `sync/domain/` is the step that makes adapters fully interchangeable; any new backend work should start there.

### Changing the backend

1. Implement the sync contract in a new adapter under `lib/src/features/sync/data/`, including its own auth/session handling, DTOs and error translation.
2. Replace the adapter in the sync provider. No changes to `domain/`, `presentation/`, or the SQLite layer.
3. Keep backend-specific configuration (base URL, keys, namespaces) inside the adapter's own config, next to `ApiConfig`.
4. Cover the new adapter with the same contract tests as the existing one (100% line coverage still applies).
5. Document the new adapter's protocol in a section like the one below.

If the contract cannot express something the new backend needs, extend the contract in domain terms, not with backend-specific types.

## Configuration

Pass `API_BASE_URL` when compiling or running the Flutter app. The Android project configures Gradle product flavors (`dev`, `preview`, `prod`), so `--flavor dev` (or the target flavor) is required on Android:

```bash
flutter run \
  --flavor dev \
  --dart-define=API_BASE_URL=<backend-url>
```

`./build-aab.sh` reads `API_BASE_URL` from the environment. Without it the app runs local-only (no sync or sharing). See "Running in Development" in the README for emulator, device and desktop commands.

## HTTP/Socket.IO Adapter Protocol

This is the protocol `ApiSyncService` speaks. Any backend exposing it works with the app without code changes.

### Endpoints & Namespaces

- **REST Base URL**: `${API_BASE_URL}/api/v1`
- **Realtime Gateway**: `${API_BASE_URL}/realtime` (Socket.IO namespace `/realtime`)
- **Public Invite Landing**: `${API_BASE_URL}/join/:credential`

### Authentication

Invisible anonymous authentication:
- `POST /api/v1/auth/anonymous`: creates a user session with an access token and a refresh token.
- `POST /api/v1/auth/refresh`: rotates the refresh token and returns a new access token.
- Tokens are persisted securely on-device using `flutter_secure_storage`.
- Requests refresh the access token when it nears expiration or on an HTTP 401 response.

### Sharing and Joining Lists

1. The client calls `POST /api/v1/lists/:listId/invites`.
2. The server returns an invite with a short human-friendly code, a long token, and the full `inviteUrl`.
3. When another user opens the link or enters the token in "Join a list", the client calls `POST /api/v1/invites/join`.
4. The server validates the credential and enforces the 5-member limit atomically.
5. The full list snapshot is returned to the client and saved to local SQLite.
6. The client joins the realtime room by emitting `list:subscribe` with `{ listId: "<list-id>" }`.
7. When list changes occur, the server broadcasts `list.changed`. Subscribed clients pull updated snapshots via `GET /api/v1/lists/:listId`.
8. When offline, mutations are recorded in the local SQLite `pending_operations` table. Once connectivity resumes, `ApiSyncService` replays queued operations via `PUT` and `DELETE` requests.
