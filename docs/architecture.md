# Listix Architecture & Design Document

## 1. Executive Summary

Listix is a fast, minimalist, **offline-first** checklist and shopping list application. It is engineered around instant responsiveness, zero-lag local SQLite persistence, real-time multi-device collaboration through a pluggable backend adapter, and full data sovereignty with on-device backup and restore.

### Scope Matrix

| Feature | Status | Implementation Details |
| :--- | :--- | :--- |
| **List Management** | ✅ | Create, view, edit name, delete, star, sort, grid/list layout toggle |
| **Friction-Free Item Entry** | ✅ | Fixed bottom input, enter/tap submit, auto-refocus |
| **Item Interaction** | ✅ | Animated custom checkbox, strikethrough typography animation, opacity dimming, collapsible completed group, swipe-to-delete |
| **List Sharing & Collaboration** | ✅ | Socket.IO Realtime synchronization, anonymous token invites, web & deep-link joining (`listix://join/:token`), active presence avatars, 5-member limit enforcement |
| **Sync Visual States** | ✅ | Realtime presence badge, discrete sync indicator, offline mutation queueing |
| **Offline Persistence** | ✅ | On-device SQLite database with atomic transactions and WAL mode |
| **Real-Time Synchronization**| ✅ | Realtime channels and atomic member-limit enforcement through the backend adapter (see [`backend.md`](backend.md)) |
| **Backup & Restore** | ✅ | Full JSON schema v1 export/import, CSV spreadsheet export, Plain Text checklist summaries, Android Storage Access Framework (SAF) native document picker/creator, share sheets, merge/overwrite conflict resolution |
| **AdMob Ads (Banner & Interstitial)**| ✅ | Google Mobile Ads integration with anchored adaptive banners, interstitial preloading, and user consent handling |
| **Notifications & Preferences** | ✅ | Local notifications scheduling, Material 3 appearance switching (Light/Dark/System), bilingual internationalization (EN/ES) |
| **Navigation** | ✅ | Declarative routing with `go_router` (`/`, `/lists/new`, `/list/:id`, `/list/:id/edit`, `/settings`, `/backup`, `/join/:token`, `/about`) |
| **Quantities & Units** | ❌ (V2) | Deferred to maintain minimal focused UX |
| **Prices & Budgets** | ❌ (V2) | Deferred |
| **Item Categories & Icons**| ❌ (V2) | Deferred |

---

## 2. Layered Architecture

Listix implements **Clean Architecture** organized with a **Feature-First** structure adhering to [AGENTS.md](../AGENTS.md):

```text
lib/
├── main.dart                               # App bootstrap with ProviderScope
└── src/
    ├── app.dart                            # MaterialApp.router with themeMode & localization delegates
    ├── routing/                            # Declarative navigation with GoRouter
    │   ├── app_router.dart                 # Route definitions and deep link parser
    │   └── routes.dart                     # Type-safe route paths
    ├── features/
    │   ├── about/                          # About screen & legal metadata
    │   │   └── presentation/screens/about_screen.dart
    │   ├── ads/                            # Google Mobile Ads integration
    │   │   ├── data/                       # Ad configurations & interstitial service
    │   │   │   ├── ad_config.dart
    │   │   │   └── interstitial_ad_service.dart
    │   │   └── presentation/               # Banner controller & adaptive banner widget
    │   │       ├── controllers/banner_ad_controller.dart
    │   │       └── widgets/banner_ad_widget.dart
    │   ├── backup/                         # Data sovereignty, backup & restore module
    │   │   ├── domain/                     # Entities, contracts & failure types
    │   │   │   ├── entities/               # BackupData (v1), BackupResult
    │   │   │   ├── failures/backup_failure.dart
    │   │   │   └── repositories/backup_repository.dart
    │   │   ├── data/                       # Local SQLite backup & Android SAF service
    │   │   │   ├── datasources/
    │   │   │   │   ├── backup_local_data_source.dart
    │   │   │   │   └── native_file_service.dart
    │   │   │   └── repositories/backup_repository_impl.dart
    │   │   └── presentation/               # Backup state, controller & screen
    │   │       ├── controllers/
    │   │       │   ├── backup_controller.dart
    │   │       │   └── backup_state.dart
    │   │       └── screens/backup_screen.dart
    │   ├── collaboration/                  # Realtime & invite tokens
    │   │   ├── domain/                     # Collaboration contracts & invite token service
    │   │   │   ├── entities/               # CollaborationEvent, CollaborationExceptions
    │   │   │   ├── repositories/collaboration_repository.dart
    │   │   │   └── services/invite_token_service.dart
    │   │   ├── data/                       # API & WebSocket repositories
    │   │   │   └── repositories/
    │   │   │       ├── api_collaboration_repository.dart
    │   │   │       └── websocket_collaboration_repository.dart
    │   │   └── presentation/               # Presence widgets, join dialog & invite screen
    │   │       ├── controllers/collaboration_controller.dart
    │   │       ├── screens/join_invite_screen.dart
    │   │       └── widgets/
    │   │           ├── join_list_dialog.dart
    │   │           └── realtime_presence_badge.dart
    │   ├── lists/                          # Core lists and items domain, SQLite repo & UI
    │   │   ├── domain/                     # Pure Dart models & repository contracts
    │   │   │   ├── entities/               # ShoppingList, TodoItem, Collaborator
    │   │   │   └── repositories/lists_repository.dart
    │   │   ├── data/                       # SQLite data layer
    │   │   │   └── repositories/sqlite_lists_repository.dart
    │   │   └── presentation/               # Riverpod controllers, screens & widgets
    │   │       ├── controllers/
    │   │       │   ├── lists_controller.dart
    │   │       │   └── list_layout_controller.dart
    │   │       ├── services/share_service.dart
    │   │       ├── screens/
    │   │       │   ├── create_edit_list_screen.dart
    │   │       │   ├── home_screen.dart
    │   │       │   ├── list_detail_screen.dart
    │   │       │   └── share_list_sheet.dart
    │   │       └── widgets/
    │   │           ├── collaborator_tile.dart
    │   │           ├── list_card.dart
    │   │           ├── list_grid_card.dart
    │   │           ├── quick_add_input.dart
    │   │           └── todo_item_tile.dart
    │   ├── notifications/                  # Local notifications management
    │   │   ├── data/services/notification_service.dart
    │   │   └── presentation/controllers/notifications_controller.dart
    │   ├── settings/                       # Theme mode & app preferences
    │   │   └── presentation/screens/settings_screen.dart
    │   └── sync/                           # Background sync coordination
    │       ├── domain/                     # Sync status & pending operation models
    │       │   ├── pending_operation.dart
    │       │   └── sync_status.dart
    │       ├── data/                       # REST sync & mock engine fallback
    │       │   ├── mock_backend_sync_service.dart
    │       │   └── api_sync_service.dart
    │       └── presentation/               # Sync controller & status indicator
    │           ├── sync_controller.dart
    │           └── widgets/sync_status_badge.dart
    └── core/                               # Cross-cutting foundational modules
        ├── config/                         # Environment & API configuration
        │   ├── api_config.dart
        │   └── app_environment.dart
        ├── localization/                   # Bilingual ARB strings & locale controller
        │   ├── app_strings.dart
        │   ├── locale_controller.dart
        │   └── generated/
        ├── network/                        # HTTP client & session management
        │   ├── api_client.dart
        │   ├── api_exception.dart
        │   └── auth_session_service.dart
        ├── services/                       # URL launcher service
        │   └── url_launcher_service.dart
        ├── storage/                        # SQLite AppDatabase and table definitions
        │   └── app_database.dart
        ├── theme/                          # Material 3 Teal/Slate palette, dark/light themes
        │   ├── app_colors.dart
        │   ├── app_theme.dart
        │   └── theme_controller.dart
        └── widgets/                        # Reusable core widgets
            ├── empty_state_widget.dart
            ├── listix_logo.dart
            └── sync_indicator.dart
```

---

## 3. Key Technical Decisions

### A. State Management: Riverpod (`AsyncNotifier` & `Notifier`)
- **Decoupled Business Logic**: Controllers run independently of the widget tree, allowing isolated unit testing without UI harness overhead.
- **Unidirectional Reactive Flow**: UI components observe state (`ref.watch`) while callbacks dispatch mutations to notifiers (`ref.read(provider.notifier).method()`).
- **Granular Re-renders**: Scoped providers and family providers (`shoppingListProvider(id)`) limit rebuilds strictly to modified items or active lists.

### B. Local-First SQLite Persistence
- **Zero-Latency Storage**: All user actions (creating lists, toggling items, reordering) commit immediately to local SQLite via atomic transactions.
- **Offline Mutation Tracking**: Pending modifications log into `pending_operations` with `is_synced = 0`.
- **Foreign Key Cascades**: Database schema enforces `PRAGMA foreign_keys = ON` ensuring cascaded deletion of items and collaborators when a list is removed.
- **Database Architecture Documentation**: See [docs/database.md](database.md) for full schema definitions, indices, and query optimizations.

### C. Real-Time Collaboration & Backend Synchronization
- **WebSocket Broadcast & Presence**: Shared lists establish Socket.IO connections to the `/realtime` namespace. Realtime updates notify clients when lists or items change.
- **Secure Token-Based Invites**: Share links encode cryptographically generated tokens managed by the backend.
- **Transactional Member Limit Enforcement**: The backend verifies token validity and enforces a strict 5-collaborator maximum atomically.
- **Deep Linking Integration**: Android App Links and custom URL schemes (`listix://join/:token`) route users straight to `JoinInviteScreen`.
- **Deterministic Conflict Resolution**: Last-Write-Wins (LWW) conflict resolution handles concurrent multi-device sync safely.

### D. Backup, Data Portability & Android Storage Access Framework (SAF)
- **Data Sovereignty**: Complete offline backup and restore without mandatory cloud accounts or external lock-in.
- **Schema v1 JSON Standard**: Full database snapshot containing application version, export timestamp, and nested lists with all item attributes.
- **Universal Formats**: Supports CSV export for spreadsheets (Excel, Google Sheets) and formatted Plain Text checklists for quick notes and messaging.
- **Native Android SAF Channel**:
  - `MainActivity.kt` registers `com.nmenag.listix/native_file_system`.
  - Uses `Intent.ACTION_CREATE_DOCUMENT` for direct file creation in user-selected storage locations without demanding broad storage permissions.
  - Uses `Intent.ACTION_OPEN_DOCUMENT` to securely select and stream backup files into the app.
  - Falls back to `share_plus` native share sheets when SAF is not available.
- **Atomic Restoration Strategies**:
  - **Replace Existing**: Clears local lists and imports backup entities inside a single atomic SQLite transaction with full rollback on validation failure.
  - **Merge**: Appends missing lists and items while keeping existing local data intact.

### E. Mobile Advertising Architecture (Google Mobile Ads)
- **Adaptive Bottom Banners**: Anchored banners (`BannerAdWidget`) automatically calculate container dimensions to match screen width without layout jank.
- **Interstitial Lifecycle Management**: `InterstitialAdService` preloads full-screen interstitials in the background and respects user dismissal timers.
- **Graceful Fallbacks**: Ad errors and offline conditions fail silently without obstructing user workflows or degrading performance.

### F. Local Notifications & Periodic Scheduling
- **Reminder Engine**: `NotificationService` leverages `flutter_local_notifications` for scheduled shopping reminders and collaborative list update alerts.
- **Permission Governance**: Requests notification permissions transparently through the Settings screen with reactive state handling.

### G. Gesture & Animation Choices (Impeccable Craft Floor)
- **Native Swipe-to-Delete**: Responsive `Dismissible` implementation with color transitions, icons, and tactile confirmation dialogues.
- **Ergonomic Thumb Reach**: Fixed bottom input (`QuickAddInput`) enables one-handed grocery list building on modern mobile displays.
- **Collapsible Completed Grouping**: Finished items drop to the bottom with 0.45 opacity and strikethrough typography animation, preserving focus on pending grocery items.
- **Real-Time Presence Badges**: Visual indicator displaying live collaborator counts and avatar indicators on shared lists.
