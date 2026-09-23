# Listix Architecture & Design Document

## 1. Executive Summary

Listix is a fast, minimalist, **offline-first** checklist and shopping list application. It is engineered around instant responsiveness, zero-lag local SQLite persistence, discrete background synchronization, and a clean ad monetization architecture.

### Scope Matrix

| Feature | Status | Implementation Details |
| :--- | :--- | :--- |
| **List Management** | ✅ | Create, view, edit name, delete lists |
| **Friction-Free Item Entry** | ✅ | Fixed bottom input, enter/tap submit, auto-refocus |
| **Item Interaction** | ✅ | Animated strikethrough, collapsible completed group, swipe-to-delete |
| **List Sharing (UI)** | ✅ | Bottom sheet, invite by email, copy invite link, remove collaborator |
| **Sync Visual States** | ✅ | Discrete amber indicator for un-synced local data |
| **Offline Persistence** | ✅ | On-device SQLite database with atomic transactions |
| **Mock Background Sync**| ✅ | Mock engine that reconciles un-synced items asynchronously |
| **AdMob Ads (Banner & Interstitial)**| ✅ | Mock AdMob service with official test IDs, anchored banner & full-screen interstitial |
| **Navigation** | ✅ | Declarative routing with `go_router` |
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
    ├── app.dart                            # MaterialApp.router with custom AppTheme
    ├── core/                               # Cross-cutting foundational modules
    │   ├── storage/                        # SQLite persistence layer
    │   │   └── app_database.dart
    │   ├── theme/
    │   │   ├── app_colors.dart             # Distinctive Teal/Slate color palette
    │   │   └── app_theme.dart              # Material 3 ThemeData with craft floor rules
    │   └── widgets/
    │       ├── empty_state_widget.dart     # Minimalist empty state with action button
    │       └── sync_indicator.dart         # Discrete un-synced entity dot
    ├── routing/                            # Declarative navigation with GoRouter
    │   ├── app_router.dart
    │   └── routes.dart
    └── features/
        ├── ads/                            # Google AdMob integration module
        │   ├── domain/                     # Entities & AdMob service contract
        │   │   ├── entities/               # AdmobAdState, AdmobBannerSize, MockAdmobCampaign
        │   │   └── repositories/           # AdmobService interface
        │   ├── data/                       # Mock data source & test unit IDs
        │   │   ├── datasources/            # AdmobUnitIds (official Google AdMob test IDs)
        │   │   └── repositories/           # MockAdmobService
        │   └── presentation/               # Riverpod controller & AdMob widgets
        │       ├── controllers/            # AdmobController, providers
        │       └── widgets/                # AdmobBannerWidget, AdmobInterstitialDialog
        ├── lists/                          # Lists & Todo feature module
        │   ├── domain/                     # Entities & abstract repository contracts
        │   │   ├── entities/               # ShoppingList, TodoItem, Collaborator
        │   │   └── repositories/           # ListsRepository interface
        │   ├── data/                       # SQLite data layer
        │   │   └── repositories/           # SqliteListsRepository
        │   └── presentation/               # Riverpod controllers, UI screens & widgets
        │       ├── controllers/            # ListsController (AsyncNotifier)
        │       ├── widgets/                # ListCard, TodoItemTile, QuickAddInput, CollaboratorTile
        │       └── screens/
        │           ├── create_edit_list_screen.dart
        │           ├── home_screen.dart
        │           ├── list_detail_screen.dart
        │           └── share_list_sheet.dart
        └── sync/                           # Background sync module
            ├── domain/
            │   └── sync_status.dart
            ├── data/
            │   └── mock_backend_sync_service.dart
            └── presentation/
                ├── sync_controller.dart
                └── widgets/
                    └── sync_status_badge.dart
```

---

## 3. Key Technical Decisions

### A. State Management: Riverpod (`AsyncNotifier` & `Notifier`)
- **Independence from `BuildContext`**: Business logic and repositories can be tested and mutated outside the widget tree.
- **Unidirectional Reactive Flow**: UI components watch state (`ref.watch`) while user interactions trigger actions on notifiers (`ref.read(provider.notifier).method()`).
- **Family Providers**: Uses `shoppingListProvider(id)` to confine widget re-renders to only the list being observed.

### B. Local-First SQLite Persistence
- **On-Device SQLite**: Replaces in-memory mocks with production SQLite storage via `sqflite` + `sqflite_common_ffi` (Linux/Desktop & Android/iOS support).
- **Background Sync Simulation**: User interactions execute instantly locally with `is_synced = 0`. An asynchronous worker batches and pushes changes in the background, updating them to `is_synced = 1`.
- **Database Architecture Documentation**: See [docs/database.md](database.md) for table definitions, ER diagram, indexing, and migration planning.

### C. Gesture & Animation Choices (Impeccable Craft Floor)
- **Native `Dismissible`**: Clean swipe-to-delete with native feedback and single-elevation cards (crisp borders, no ghost card double-elevation).
- **Ergonomic Bottom Bar (`QuickAddInput`)**: Positioned at the bottom for easy thumb reach on mobile displays.
- **Collapsible Completed Section**: Groups checked items at the bottom with a 0.45 opacity and strikethrough animation, keeping the primary focus on pending items.
- **Sync Status Interaction**: Interactive status pill in the AppBar allowing the user to view sync state, trigger immediate reconciliation, or toggle simulated offline mode.

### D. Google AdMob Mock Service (Banner & Interstitial)
- **Zero Native SDK Lock-in**: Decouples ad business logic from native platform builds (`google_mobile_ads` lacks native Linux desktop support and causes build/test crashes).
- **Domain Contract (`AdmobService`)**: Specifies AdMob lifecycle operations (`initialize`, `loadBannerAd`, `loadInterstitialAd`, `showInterstitialAd`, streams, and click tracking).
- **Official Google Test Ad Unit IDs**:
  - Banner: `ca-app-pub-3940256099942544/6300978111` (Android) / `ca-app-pub-3940256099942544/2934735716` (iOS)
  - Interstitial: `ca-app-pub-3940256099942544/1033173712` (Android) / `ca-app-pub-3940256099942544/4411468910` (iOS)
- **Banner Ad (`AdmobBannerWidget`)**: Anchored adaptive bottom banner widget with official AdMob badge styling, sponsor name, interactive CTA button, and click telemetry.
- **Interstitial Ad (`AdmobInterstitialDialog`)**: Full-screen modal overlay simulating Google AdMob interstitials with countdown skip timer (4s), rich creative preview card, star ratings, and preloading of subsequent ads upon dismissal.
- **Natural Frequency & Triggers**:
  - Interstitial is shown naturally when creating a new shopping list.
  - Manual trigger button (`Icons.ads_click_rounded`) in `HomeScreen` AppBar for instant testing.
  - Anchored banner ad in `HomeScreen.bottomNavigationBar`.
