# Listix Worker Backend Integration

This guide describes how to configure the Listix Worker backend for Listix collaborative lists, set environment variables, and validate offline-first synchronization across devices.

## Architecture Overview

The Listix backend (`listix-worker`) is a NestJS application backed by PostgreSQL (Prisma ORM) and Socket.IO for real-time collaboration.

### Core Endpoints & Namespaces

- **REST Base URL**: `${API_BASE_URL}/api/v1`
- **Realtime Gateway**: `${API_BASE_URL}/realtime` (Socket.IO namespace `/realtime`)
- **Public Invite Landing**: `${API_BASE_URL}/join/:credential`

### Authentication

Listix utilizes invisible anonymous authentication:
- `POST /api/v1/auth/anonymous`: Generates a user session with a JWT access token (15-min TTL) and refresh token (90-day TTL).
- `POST /api/v1/auth/refresh`: Rotates refresh tokens and provides a new access token.
- Tokens are persisted securely on-device using `flutter_secure_storage`.
- Requests automatically refresh access tokens when nearing expiration or upon encountering an HTTP 401 response.

## Environment Variables & Compilation

Pass `API_BASE_URL` when compiling or running the Flutter app. Note that the Android project configures Gradle product flavors (`dev`, `preview`, `prod`), so `--flavor dev` (or target flavor) is required when running on Android:

```bash
flutter run \
  --flavor dev \
  --dart-define=API_BASE_URL=https://listix-worker.onrender.com
```

During local development with Docker:

```bash
flutter run \
  --flavor dev \
  --dart-define=API_BASE_URL=http://localhost:3000
```

`API_BASE_URL` defaults to the deployed backend `https://listix-worker.onrender.com`. To use a local listix-worker pass `--dart-define=API_BASE_URL=http://localhost:3000`. See "Running in Development" in the README for emulator, device and desktop commands.

## Sharing and Joining Lists

When a user shares a list:
1. The client calls `POST /api/v1/lists/:listId/invites`.
2. The server creates an invite record with a short human-friendly code and long token, returning the full `inviteUrl`.
3. When another user opens the link or enters the token in "Join a list", the client calls `POST /api/v1/invites/join`.
4. The server validates the credential and enforces the 5-member limit within a PostgreSQL transaction using advisory locking.
5. The full list snapshot is returned to the client and saved to local SQLite.
6. The client joins the Socket.IO room by emitting `list:subscribe` with `{ listId: "<list-id>" }`.
7. When list changes occur, the server broadcasts `list.changed`. Subscribed clients receive this event and pull updated snapshots via `GET /api/v1/lists/:listId`.
8. When offline, mutations are recorded in the local SQLite `pending_operations` table. Once network connectivity resumes, `ApiSyncService` replays queued operations via `PUT` and `DELETE` requests.
