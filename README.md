# Listix

[![CI](https://github.com/nmenag/listix/actions/workflows/ci.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/ci.yml)
[![PR Checks](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml)
[![Release](https://github.com/nmenag/listix/actions/workflows/release.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/release.yml)

A fast, minimalist, **offline-first** shopping and checklist mobile application built with Flutter, Dart 3, Material 3, SQLite local persistence, and Riverpod.

---

## 🎯 Overview & Vision

Listix is engineered for high-speed, everyday grocery and checklist management with an uncompromising commitment to local performance and user privacy:
- **Offline-First (100% Local SQLite)**: Instant operations with zero input lag. All lists and items are persisted locally on your device in SQLite. No network connection is needed to organize your lists.
- **Sync Exclusively Upon Sharing**: Continuous background network syncing is eliminated. Lists are synchronized cleanly and specifically when sharing.
- **Native WhatsApp & Gmail Sharing**: Share formatted lists directly through WhatsApp (`whatsapp://`) or Gmail (`mailto:`) with clear checkboxes and item groupings, or copy to clipboard in one tap.
- **Dark Mode, Light Mode & System Default**: Tailored Material 3 themes with an intuitive appearance switcher in Settings.
- **Bilingual (English & Spanish)**: Full internationalization support with instant in-app language switching and system locale fallback.
- **App Store Optimization (ASO)**: Optimized metadata, keyword targeting, and concise benefit-driven microcopy (see [ASO Strategy](docs/ASO_COPY_OPTIMIZATION.md)).
- **Automated GitHub Releases**: CI/CD release workflow to build release APKs and App Bundles (AAB) with automated changelogs.

---

## 📱 Feature Scope

| Screen / Flow | Description |
| :--- | :--- |
| **1. Home / Lists Overview** | Scalable `ListixLogo` header, Settings action shortcut, list cards with real-time pending progress badges, pull-to-refresh local reload, and swipe-to-delete with confirmation dialog. |
| **2. List Detail (ToDo Style)** | Header with list title, rename shortcut, share sheet trigger, pending/completed counter with progress bar, and instant quick-add bottom bar. |
| **⚡ Quick Item Add** | Bottom input bar. Type item title and submit to immediately append to SQLite without leaving the keyboard. |
| **✓ Interactive Items** | Animated custom checkbox, strikethrough typography animation, opacity dimming for finished items, collapsible completed group, and swipe-to-delete. |
| **3. Create / Edit List** | Minimalist single-input focus screen for creating or renaming lists saved locally in SQLite. |
| **4. Share List (Modal Sheet)** | One-tap sharing via **WhatsApp**, **Gmail / Native Email**, or **Copy to Clipboard**. Syncs the list on share. |
| **5. Settings & Appearance** | Appearance selector (**System Default**, **Light Mode**, **Dark Mode**), language switcher (**Español** / **English**), offline-first transparency card, Privacy Policy, Terms of Service, and version info. |

---

## 🏛️ Architecture & Project Structure

Listix adheres to **Feature-First Clean Architecture**:

```text
lib/
├── main.dart                               # App bootstrap with ProviderScope
└── src/
    ├── app.dart                            # MaterialApp.router with themeMode & localization delegates
    ├── core/                               # Cross-cutting foundational modules
    │   ├── localization/                   # Bilingual strings & language switcher
    │   │   ├── app_strings.dart
    │   │   └── locale_controller.dart
    │   ├── storage/                        # SQLite AppDatabase and table definitions
    │   │   └── app_database.dart
    │   ├── theme/                          # Material 3 Teal/Slate palette, dark/light themes & controller
    │   │   ├── app_colors.dart
    │   │   ├── app_theme.dart
    │   │   └── theme_controller.dart
    │   └── widgets/                        # Reusable core widgets (logo, empty states)
    │       ├── empty_state_widget.dart
    │       ├── listix_logo.dart
    │       └── sync_indicator.dart
    ├── routing/                            # Declarative navigation with GoRouter
    │   ├── app_router.dart
    │   └── routes.dart
    └── features/
        ├── about/                          # About screen & metadata
        │   └── presentation/screens/about_screen.dart
        ├── lists/                          # Core list management domain, SQLite repo & UI
        │   ├── domain/
        │   ├── data/repositories/sqlite_lists_repository.dart
        │   └── presentation/
        │       ├── controllers/lists_controller.dart
        │       ├── services/share_service.dart
        │       └── screens/
        │           ├── home_screen.dart
        │           ├── list_detail_screen.dart
        │           ├── create_edit_list_screen.dart
        │           └── share_list_sheet.dart
        ├── settings/                       # Theme mode & app preferences
        │   └── presentation/screens/settings_screen.dart
        └── sync/                           # On-demand sync capabilities
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
