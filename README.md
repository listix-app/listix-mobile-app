# Listix

[![CI](https://github.com/nmenag/listix/actions/workflows/ci.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/ci.yml)
[![PR Checks](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml)

A fast, minimalist, **offline-first** collaborative shopping and checklist mobile application built with Flutter, Dart 3, Material 3, SQLite local persistence, and Riverpod.

---

## 🎯 Overview & Vision

Listix is designed for high-speed, general-purpose list management (groceries, home hardware, clothing, personal errands). Its core long-term pillars are:
- **Offline-First (SQLite)**: Instant local operations with zero input lag. All reads and writes hit SQLite on-device first; the UI never waits for the network.
- **Friction-Free Speed**: Add and check off items without modals, extra taps, or input lag.
- **Bilingual (English & Spanish)**: Full internationalization support with instant in-app language switching and system locale fallback.
- **Privacy & Transparency**: Zero third-party trackers, zero advertising telemetry, and transparent on-device local storage.
- **Custom Brand Identity**: Native, crisp vector logo (`ListixLogo`) with scalable painter and brand wordmark.
- **Mock Background Sync**: Demonstrates real-time reconciliation where un-synced items are updated asynchronously in the background.
- **Seamless Collaboration**: Shared lists with invite links and collaborator management.
- **Budget & Price Tracking** *(Roadmap V2+)*: Spend estimates, unit prices, and store history.

---

## 📱 V1 Feature Scope

| Screen / Flow | Description |
| :--- | :--- |
| **1. Home / Lists Overview** | Scalable `ListixLogo` brand header, list cards showing list name, pending progress badge (e.g. `3 de 7 pendientes`), collaborator avatars (`+2`), visual sync indicators, pull-to-refresh sync, and swipe-to-delete with confirmation. |
| **2. List Detail (ToDo Style)** | Header with list name, inline rename shortcut, share modal trigger with collaborator counter, progress bar, and sync status badge. |
| **⚡ Quick Item Add** | Ergonomic bottom input bar. Type item name and press Enter or ✓ to append immediately to SQLite without leaving the keyboard. |
| **✓ Interactive Items** | Animated custom checkbox, strikethrough typography animation, opacity dimming for finished items, collapsible completed section, and native swipe-to-delete. |
| **3. Create / Edit List** | Minimalist single-input focus screen for creating or renaming lists. |
| **4. Share List (Modal Sheet)** | Invite collaborators by email, one-tap invite link copying to clipboard, and active collaborator roster with member removal. |
| **5. About, Policy & Privacy** | Dedicated screen presenting version info, mission statement, in-app language selector (Español / English), transparent Privacy Policy, and Terms of Service. |
| **6. Sync Status Badge & Mode** | Interactive status badge in the AppBar (`Sincronizado`, `Sincronizando...`, `Offline`). Includes simulated offline mode toggle to test local-first operations. |

---

## 🏛️ Architecture & Project Structure

Listix adheres to **Feature-First Clean Architecture**:

```text
lib/
├── main.dart                               # App bootstrap with ProviderScope
└── src/
    ├── app.dart                            # MaterialApp.router with localization delegates
    ├── core/                               # Cross-cutting foundational modules
    │   ├── localization/                   # Bilingual strings & language switcher
    │   │   ├── app_strings.dart
    │   │   └── locale_controller.dart
    │   ├── storage/                        # SQLite AppDatabase and table definitions
    │   │   └── app_database.dart
    │   ├── theme/                          # Material 3 custom Teal/Slate palette & craft tokens
    │   │   ├── app_colors.dart
    │   │   └── app_theme.dart
    │   └── widgets/                        # Reusable core widgets
    │       ├── empty_state_widget.dart     # Polished empty state with CTA
    │       ├── listix_logo.dart            # Custom scalable vector brand logo & painter
    │       └── sync_indicator.dart         # Non-intrusive sync reservation dot
    ├── routing/                            # Declarative navigation with GoRouter
    │   ├── app_router.dart
    │   └── routes.dart
    └── features/
        ├── about/                          # About screen, Privacy Policy, Terms & Language switcher
        │   └── presentation/screens/about_screen.dart
        ├── lists/                          # Core list management domain, SQLite repo & UI
        │   ├── domain/
        │   ├── data/repositories/sqlite_lists_repository.dart
        │   └── presentation/
        └── sync/                           # Background synchronization engine
            ├── domain/sync_status.dart
            ├── data/mock_backend_sync_service.dart
            └── presentation/
```

---

## 🧪 Testing & Quality Assurance

The test suite covers unit, widget, and integration tests across all features with a strict **100% test coverage** requirement enforced via CI:

```bash
# Run all unit and widget tests
flutter test

# Run test suite and generate coverage profile
flutter test --coverage test/all_tests_coverage.dart

# Enforce strict 100% test coverage verification
dart run tool/verify_coverage.dart

# Run static code analysis
flutter analyze

# Verify code formatting
dart format --output=none --set-exit-if-changed .
```

---

## 📄 License

MIT License. Designed and built with Flutter and SQLite.
