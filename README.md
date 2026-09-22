# Listix

[![CI](https://github.com/nmenag/listix/actions/workflows/ci.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/ci.yml)
[![PR Checks](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml)

A fast, minimalist, **offline-first** collaborative shopping and checklist mobile application built with Flutter, Dart 3, Material 3, SQLite local persistence, and Riverpod.

---

## 🎯 Overview & Vision

Listix is designed for high-speed, general-purpose list management (groceries, home hardware, clothing, personal errands). Its core long-term pillars are:
- **Offline-First (SQLite)**: Instant local operations with zero input lag. All reads and writes hit SQLite on-device first; the UI never waits for the network.
- **Friction-Free Speed**: Add and check off items without modals, extra taps, or input lag.
- **Mock Background Sync**: Demonstrates real-time reconciliation where un-synced items are updated asynchronously in the background.
- **AdMob Mock Ads**: Integrated Google AdMob service simulation (adaptive bottom banners and full-screen countdown interstitials) with standard test IDs.
- **Seamless Collaboration**: Shared lists with invite links and collaborator management.
- **Budget & Price Tracking** *(Roadmap V2+)*: Spend estimates, unit prices, and store history.

---

## 📱 V1 Feature Scope

| Screen / Flow | Description |
| :--- | :--- |
| **1. Home / Lists Overview** | List cards showing list name, pending progress badge (e.g. `"3 de 7 pendientes"`), collaborator avatars (`+2`), visual sync indicators, pull-to-refresh sync, and swipe-to-delete with confirmation. |
| **2. List Detail (ToDo Style)** | Header with list name, inline rename shortcut, share modal trigger with collaborator counter, progress bar, and sync status badge. |
| **⚡ Quick Item Add** | Ergonomic bottom input bar. Type item name and press Enter or ✓ to append immediately to SQLite without leaving the keyboard. |
| **✓ Interactive Items** | Animated custom checkbox, strikethrough typography animation, opacity dimming for finished items, collapsible completed section, and native swipe-to-delete. |
| **3. Create / Edit List** | Minimalist single-input focus screen for creating or renaming lists with automatic post-creation interstitial ad trigger. |
| **4. Share List (Modal Sheet)** | Invite collaborators by email, one-tap invite link copying to clipboard, and active collaborator roster with member removal. |
| **5. Sync Status Badge & Mode** | Interactive status badge in the AppBar (`Sincronizado`, `Sincronizando...`, `Offline`). Includes simulated offline mode toggle to test local-first operations. |
| **6. AdMob Banner Ad** | Anchored adaptive banner at the bottom of the home screen featuring AdMob test badges, sponsor metadata, and click simulation. |
| **7. AdMob Interstitial Ad** | Full-screen modal overlay simulating Google AdMob interstitials with a 4-second countdown skip timer, rich preview card, ratings, and CTA. |

---

## 🏛️ Architecture & Project Structure

Listix adheres to **Feature-First Clean Architecture** according to [AGENTS.md](AGENTS.md) and [docs/v1_architecture.md](docs/v1_architecture.md):

```text
lib/
├── main.dart                               # App bootstrap with ProviderScope
└── src/
    ├── app.dart                            # MaterialApp.router with custom AppTheme
    ├── core/                               # Cross-cutting foundational modules
    │   ├── storage/                        # SQLite AppDatabase and table definitions
    │   │   └── app_database.dart
    │   ├── theme/                          # Material 3 custom Teal/Slate palette & craft tokens
    │   │   ├── app_colors.dart
    │   │   └── app_theme.dart
    │   └── widgets/                        # Reusable core widgets
    │       ├── empty_state_widget.dart     # Polished empty state with CTA
    │       └── sync_indicator.dart         # Non-intrusive sync reservation dot
    ├── routing/                            # Declarative navigation with GoRouter
    │   ├── app_router.dart
    │   └── routes.dart
    └── features/
        ├── ads/                            # Google AdMob mock service module
        │   ├── domain/                     # Entities & AdmobService contract
        │   │   ├── entities/               # AdmobAdState, AdmobBannerSize, MockAdmobCampaign
        │   │   └── repositories/           # AdmobService interface
        │   ├── data/                       # Official Google test IDs & mock repository
        │   │   ├── datasources/            # AdmobUnitIds
        │   │   └── repositories/           # MockAdmobService
        │   └── presentation/               # Riverpod controller & presentation widgets
        │       ├── controllers/            # AdmobController, providers
        │       └── widgets/                # AdmobBannerWidget, AdmobInterstitialDialog
        ├── lists/                          # Lists & Todo feature module
        │   ├── domain/                     # Entities & abstract repository contracts
        │   │   ├── entities/               # ShoppingList, TodoItem, Collaborator
        │   │   └── repositories/           # ListsRepository interface
        │   ├── data/                       # Offline-first SQLite implementation
        │   │   └── repositories/           # SqliteListsRepository
        │   └── presentation/               # Riverpod controllers, UI screens & widgets
        │       ├── controllers/            # ListsController (AsyncNotifier)
        │       ├── widgets/                # ListCard, TodoItemTile, QuickAddInput, CollaboratorTile
        │       └── screens/                # HomeScreen, ListDetailScreen, CreateEditListScreen, ShareListSheet
        └── sync/                           # Background synchronization module
            ├── domain/                     # SyncStatus enum
            ├── data/                       # MockBackendSyncService
            └── presentation/               # SyncController & SyncStatusBadge
```

---

## 💾 Database Architecture

Full SQLite documentation and Entity-Relationship diagrams are available in **[docs/database.md](docs/database.md)**:
- **`shopping_lists`**: Master list records with `is_synced` status and timestamps.
- **`todo_items`**: Checklist items with foreign keys, cascade deletes, and sync tracking.
- **`collaborators`**: Member roster and role mapping.
- **Indexes**: Indexed by `list_id` and `is_synced` for instant filtering.

---

## 📋 Prerequisites

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)**: `>= 3.13.3` (stable channel recommended)
- **Dart SDK**: Bundled with Flutter
- **Git**: For version control
