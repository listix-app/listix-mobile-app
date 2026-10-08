# Supabase Configuration for Listix

This guide describes how to configure the Supabase backend for Listix collaborative lists, run database migrations, set environment variables, and validate offline-first synchronization across devices.

## Prerequisites

1. Active [Supabase](https://supabase.com/) account.
2. Supabase project created with PostgreSQL and Realtime enabled.
3. Supabase CLI installed (`supabase -v`) for running local migrations or linking to a remote project.
4. Anonymous Sign-Ins enabled in the Supabase Dashboard: **Authentication -> Providers -> Anonymous Sign-Ins -> Enable**.

## Migrations

Database migrations are located in `supabase/migrations/` and define the `lists`, `list_members`, `list_items`, and `list_invites` tables, indexes, and RLS policies:

- `20260924000000_create_listix_schema.sql`: Core schema, functions (`create_list_invite`, `join_list_by_token`), indexes, and RLS.
- `20260924120000_fix_shared_list_sync_rls.sql`: `sync_shared_list` function with transactional advisory locking for collaborative lists.
- `20260927000000_add_invite_validation_rpc.sql`: `validate_list_invite` function for atomic invite validation from the Cloudflare Worker.

Apply migrations using the Supabase CLI:

```bash
# Local development with Docker
supabase db reset

# Or push to linked remote project
supabase db push
```

## Environment Variables & Compilation

Use public anonymous Supabase credentials for the Flutter client. Pass `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `INVITE_BASE_URL` when compiling:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=INVITE_BASE_URL=https://<worker-domain>/join
```

`INVITE_BASE_URL` is the base URL that precedes the invite token, e.g. `https://<worker-domain>/join`. During development, replace it with your local or deployed Cloudflare Worker URL. Configure distinct values for development, preview, and production environments via `--dart-define` build arguments. If Supabase credentials are not provided, Listix gracefully falls back to local-only SQLite mode.

## Cloudflare Worker for List Invites

The TypeScript worker in `worker/` manages:
- `GET /join/:token`: Token format validation, SHA-256 computation, Supabase verification, member limit enforcement, and serving a responsive landing page with deep link redirection (`listix://join/:token`) or fallback to Google Play (`PLAY_STORE_URL`).
- `GET /.well-known/assetlinks.json`: Android App Links domain verification.

For complete setup and deployment instructions, refer to [worker/README.md](file:///home/nmenag/personal-projects/listix/worker/README.md).

## Sharing and Joining Lists

When a user shares a list:
1. The client generates a random cryptographically secure token.
2. The client computes the SHA-256 hash and sends only the hash to `create_list_invite`.
3. The token is appended to `INVITE_BASE_URL`. The token never reveals or encodes the list ID directly.
4. When another user opens the link or enters the token, `join_list_by_token` verifies the hash, assigns the anonymous user, and strictly enforces the 5-member limit in a transaction.
5. The list data is downloaded to local SQLite; Realtime invalidates and refreshes the local copy.
6. When offline, mutations are recorded in the local SQLite `pending_operations` table. Once network connectivity resumes, `SupabaseSyncService` batches and replays queued operations via transactional RPCs, ensuring zero data loss during network dropouts.

During local testing, tokens or links can be entered directly via "Join a list" in the app. Once a public domain is provisioned, configure the matching HTTPS host in the Android intent filter and publish `/.well-known/assetlinks.json` with the application package name and SHA-256 certificate fingerprint.

## Manual Testing with Two Devices

1. Install the same development build on two devices connected to the same Supabase project. Verify Anonymous Sign-Ins is enabled.
2. On Device A, create a list, open Share, enable collaboration, and generate an invite link.
3. On Device B, open the link or paste the token into "Join a list". Verify the list and its items load locally in SQLite.
4. Add and toggle items on Device A; with both online, verify Device B receives updates via Realtime. Repeat on Device B and verify on Device A.
5. Disconnect Device B, modify the list offline, and delete an item; reconnect and confirm pending changes sync properly.
6. Repeat with additional devices or anonymous sessions up to 5 members. A 6th attempt will be rejected by the RPC.
