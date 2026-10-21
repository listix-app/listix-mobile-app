# AGENTS.md

> Architectural Guidelines and Operational Directives for AI Agents working on **Listix**.

This document outlines the mandatory engineering standards, architectural patterns, and project conventions for all AI agents and contributors working in this codebase.

> [!IMPORTANT]
> **Mandatory Context Loading**: Before starting any analysis, design, development, or refactoring task, agents MUST read the relevant domain skills in [`.agents/skills/`](.agents/skills/) and consult the architecture documentation in [`docs/`](docs/) (specifically [`docs/architecture.md`](docs/architecture.md), [`docs/database.md`](docs/database.md), and [`docs/backend.md`](docs/backend.md)).

---

## 1. Architectural Philosophy

Listix adheres to **Clean Architecture** organized with a **Feature-First** structure and **Riverpod** for state management and dependency injection.

### Core Principles
- **Separation of Concerns**: Business logic is decoupled from UI widgets, data retrieval mechanisms, and third-party SDKs.
- **Unidirectional Data Flow**: Data flows upward from Data Sources through Repositories and Controllers to the UI; events and user actions flow downward.
- **Dependency Inversion**: High-level domain logic does not depend on low-level data layer implementations. Abstract repository contracts reside in the `domain` layer and are implemented in the `data` layer.
- **Immutability & Predictability**: Domain models and states are immutable. State transitions are explicitly triggered through Riverpod Notifiers.

```
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   [ Screens / Widgets ]  ◄───►  [ Riverpod Notifiers ] │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                      Domain Layer                      │
│   [ Entities / Models ]  ◄───►  [ Repository Contract ]│
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                       Data Layer                       │
│             [ Repository Implementation ]              │
│       ┌───────────────────┴───────────────────┐        │
│       ▼                                       ▼        │
│ [ Remote Data Source ]             [ Local Data Source ]│
│ (REST / WebSocket / Realtime)      (SQLite / Hive / Prefs)
└────────────────────────────────────────────────────────┘
```

---

## 2. Directory & Package Structure

The codebase is organized **feature-first** under `lib/src/features/`. Cross-cutting, domain-agnostic logic lives under `lib/src/core/`.

```text
lib/
├── main.dart                          # App bootstrap (ProviderScope, error logging, runApp)
└── src/
    ├── app.dart                       # Root MaterialApp / CupertinoApp and theme setup
    ├── core/                          # Cross-feature, domain-agnostic foundations
    │   ├── constants/                 # App-wide constants, strings, asset references
    │   ├── exceptions/                # Base AppExceptions and Failure types
    │   ├── network/                   # HTTP client, interceptors, base API client
    │   ├── storage/                   # Database helpers, secure storage, key-value wrappers
    │   ├── theme/                     # AppTheme, color schemes, typography
    │   ├── utils/                     # Extensions, formatters, logging utilities
    │   └── widgets/                   # App-wide design system widgets (buttons, dialogs, loaders)
    │
    ├── routing/                       # App navigation (GoRouter configuration & route paths)
    │   ├── app_router.dart
    │   └── routes.dart
    │
    └── features/                      # Feature modules
        └── <feature_name>/
            ├── data/                  # Data layer: retrieval, storage, serialization
            │   ├── datasources/
            │   │   ├── <feature>_remote_data_source.dart
            │   │   └── <feature>_local_data_source.dart
            │   ├── dtos/              # Data Transfer Objects & JSON serialization
            │   │   └── <entity>_dto.dart
            │   └── repositories/      # Repository implementations
            │       └── <feature>_repository_impl.dart
            │
            ├── domain/                # Domain layer: pure Dart business rules
            │   ├── entities/          # Pure business models (immutable)
            │   │   └── <entity>.dart
            │   ├── failures/          # Domain-specific failure/exception definitions
            │   │   └── <feature>_failure.dart
            │   └── repositories/      # Abstract repository interfaces (contracts)
            │       └── <feature>_repository.dart
            │
            └── presentation/          # Presentation layer: UI & State
                ├── controllers/       # Riverpod Notifiers & state models
                │   ├── <feature>_controller.dart
                │   └── <feature>_state.dart
                ├── screens/           # Full screen views / pages
                │   └── <feature>_screen.dart
                └── widgets/           # Sub-widgets scoped specifically to this feature
                    └── <feature>_card.dart
```

---

## 3. Layer Responsibilities & Implementation Standards

### A. Data Sources (`data/datasources/`)
Data sources interact directly with external data providers (network endpoints, local databases, device sensors).

- **Remote Data Source**: Responsible for network communication (e.g., HTTP requests via Dio/http).
  - Handles HTTP status codes, headers, and payload serialization/deserialization.
  - Converts raw JSON maps to DTOs.
  - Throws typed data-layer exceptions (e.g., `ServerException`, `UnauthorizedException`, `NetworkException`).
- **Local Data Source**: Responsible for local persistence (e.g., SQLite, Hive, Isar, SharedPreferences, SecureStorage).
  - Handles caching, key-value storage, and local schema queries.
  - Throws typed data-layer exceptions (e.g., `CacheException`).
- **Rules**:
  - Never return UI or Domain models directly from data sources; return DTOs or primitive values.
  - Expose data sources via Riverpod providers.

```dart
// Example: lib/src/features/items/data/datasources/items_remote_data_source.dart
abstract class ItemsRemoteDataSource {
  Future<List<ItemDto>> fetchItems();
  Future<ItemDto> createItem(Map<String, dynamic> payload);
}

class ItemsRemoteDataSourceImpl implements ItemsRemoteDataSource {
  final Dio _dio;

  ItemsRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ItemDto>> fetchItems() async {
    try {
      final response = await _dio.get('/items');
      final data = response.data as List<dynamic>;
      return data.map((json) => ItemDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(message: e.message ?? 'Server error', statusCode: e.response?.statusCode);
    }
  }
}

// Riverpod Provider
final itemsRemoteDataSourceProvider = Provider<ItemsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ItemsRemoteDataSourceImpl(dio);
});
```

---

### B. Repository (`domain/repositories/` & `data/repositories/`)
The Repository acts as a mediator between the Domain layer and the Data Sources.

1. **Domain Repository Contract (`domain/repositories/<feature>_repository.dart`)**:
   - Defines the abstract contract using Domain entities.
   - Independent of Flutter or external libraries.
   - Returns either direct Domain entities or a functional Result/Either type.

2. **Repository Implementation (`data/repositories/<feature>_repository_impl.dart`)**:
   - Implements the domain contract.
   - Coordinates remote and local data sources (e.g., cache-first, network-first, offline sync).
   - Maps DTOs (`toDomain()`) to Domain entities.
   - Catches data-source exceptions and translates them into domain `Failure` objects or domain exceptions.

```dart
// Contract: lib/src/features/items/domain/repositories/items_repository.dart
abstract class ItemsRepository {
  Future<List<Item>> getItems();
  Future<Item> addItem({required String title, required String description});
}

// Implementation: lib/src/features/items/data/repositories/items_repository_impl.dart
class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsRemoteDataSource _remoteDataSource;
  final ItemsLocalDataSource _localDataSource;

  ItemsRepositoryImpl({
    required ItemsRemoteDataSource remoteDataSource,
    required ItemsLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<List<Item>> getItems() async {
    try {
      final dtos = await _remoteDataSource.fetchItems();
      await _localDataSource.cacheItems(dtos);
      return dtos.map((dto) => dto.toDomain()).toList();
    } on ServerException {
      // Fallback to local cache if offline
      final cachedDtos = await _localDataSource.getCachedItems();
      if (cachedDtos.isNotEmpty) {
        return cachedDtos.map((dto) => dto.toDomain()).toList();
      }
      throw const ItemsFailure(message: 'Unable to load items from server or local cache.');
    }
  }
}

// Riverpod Provider
final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final remote = ref.watch(itemsRemoteDataSourceProvider);
  final local = ref.watch(itemsLocalDataSourceProvider);
  return ItemsRepositoryImpl(remoteDataSource: remote, localDataSource: local);
});
```

---

### C. Domain Entities (`domain/entities/`)
- Encapsulate the core business models.
- Must be **pure Dart** classes without Flutter widget references or JSON serialization logic.
- Use immutable classes (e.g., Dart 3 classes with `final` fields and `copyWith`, or Freezed).

```dart
// Example: lib/src/features/items/domain/entities/item.dart
class Item {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
  });

  Item copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

---

### D. Presentation & Riverpod State Management (`presentation/`)

#### 1. Controllers / Notifiers (`presentation/controllers/`)
- Extend `AsyncNotifier<T>` (for asynchronous operations) or `Notifier<T>` (for synchronous state).
- Expose state as `AsyncValue<T>` to naturally handle loading, error, and data states.
- Handle user intents, call repositories, and update state using `state = const AsyncLoading()` and `AsyncValue.guard()`.

```dart
// Example: lib/src/features/items/presentation/controllers/items_controller.dart
class ItemsController extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    return _fetchItems();
  }

  Future<List<Item>> _fetchItems() {
    final repository = ref.watch(itemsRepositoryProvider);
    return repository.getItems();
  }

  Future<void> addItem({required String title, required String description}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(itemsRepositoryProvider);
      await repository.addItem(title: title, description: description);
      return _fetchItems();
    });
  }
}

// Controller Provider
final itemsControllerProvider = AsyncNotifierProvider<ItemsController, List<Item>>(
  ItemsController.new,
);
```

#### 2. Screens and Widgets (`presentation/screens/` & `widgets/`)
- Extend `ConsumerWidget` or `ConsumerStatefulWidget`.
- Use `ref.watch()` inside the `build()` method to reactively rebuild when state changes.
- Use `ref.read()` inside callbacks, event handlers, and button presses.
- Use `state.when(...)` to render Loading, Error, and Data views gracefully.
- Keep widgets small and decomposed; extract reusable components to `presentation/widgets/`.

```dart
// Example: lib/src/features/items/presentation/screens/items_screen.dart
class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: itemsAsync.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => ItemTile(item: items[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(itemsControllerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Operational Rules for AI Agents

1. **Always Follow Feature-First**:
   - When creating a new capability (e.g., `auth`, `settings`, `tasks`), create a dedicated folder under `lib/src/features/<feature>/` with `data/`, `domain/`, and `presentation/` subdirectories.
2. **Never Bypass Repositories**:
   - Controllers must never call DataSources directly.
   - UI Widgets must never call Repositories or DataSources directly.
3. **Keep Domain Pure**:
   - No `package:flutter` imports inside `domain/` (except annotations if strictly necessary, but prefer pure Dart).
   - Domain entities should never contain JSON serialization logic (`fromJson` / `toJson`); that belongs in `data/dtos/`.
4. **Use Riverpod Correctly**:
   - `ref.watch()` in `build()` methods.
   - `ref.read()` in event handlers / user interactions.
   - Use `AsyncValue.guard()` for asynchronous mutations.
   - Use `ref.invalidate()` or `ref.refresh()` to reload data.
5. **Testing & 100% Line Coverage Requirements**:
   - Maintain strict 100.0% line test coverage across all production code in `lib/src/` (`dart run tool/verify_coverage.dart`).
   - Data sources: test HTTP/database failure modes and successful JSON decoding.
   - Repositories: test offline caching fallback, DTO-to-entity mapping, and error translation.
   - Controllers: test state transitions (`loading` -> `data` / `error`).
   - Widgets: test UI rendering with `ProviderScope(overrides: [...])`.
6. **Code Cleanliness & Analysis**:
   - Run `flutter analyze` after making changes and resolve all errors and warnings (0 issues).
   - Follow Flutter and Dart formatting guidelines.
7. **Always Run `dart format .` After Applying Changes**:
   - **Mandatory Formatting**: Always execute `dart format .` immediately after creating, modifying, or refactoring any code or test files before proceeding to analysis or tests.
   - **Enforcement**: Ensure that `dart format .` runs cleanly and all Dart files in the workspace strictly adhere to canonical Dart formatting conventions. Never skip running `dart format .` after applying changes.
8. **Strictly No Comments on Code**:
   - **Do NOT add comments on code**: Do not write comments in production or test files. No inline comments, explanatory comments, block comments, decorative banners, or doc-comments on self-explanatory code.
   - **Self-Documenting Code**: Code must be inherently self-documenting. Use clear, intention-revealing names for classes, methods, parameters, and variables.
   - Never leave commented-out code; delete unused code completely.
9. **Strict Git Prohibitions — Never Run `git add .`, `git commit`, Nor `git push`**:
   - **Never run `git add .`**: Do NOT run `git add .` or blanket staging commands under any circumstance. Blanket staging risks staging untracked temp files, cache artifacts, credentials, or unintended modifications.
   - **Never run `git commit`**: AI agents must NEVER execute `git commit` to create commits. Commits must remain solely under the user's manual control and review. The agent's responsibility is to prepare, test, analyze, and verify code changes, leaving git commit actions entirely to the user.
   - **Never run `git push`**: AI agents must NEVER execute `git push` or publish branches to remote repositories. Pushing code is strictly reserved for the human user.
   - **No Automated Git Mutations**: Agents must not stage, commit, or push changes autonomously. The agent's role is strictly limited to authoring, formatting, analyzing, and verifying code in the local working directory.
10. **Commit & PR Conventions**:
   - Commit messages and PR titles must adhere to **Conventional Commits**: `<type>(<optional scope>): <description>`.
   - Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
   - Keep pull requests small and focused (< 500 lines of reviewed changes) to facilitate rapid, effective code reviews.
11. **Pull Request Protocol**:
   - When the user asks for a **"pull request"** (or writes "pull request"), immediately produce a comprehensive Pull Request description formatted in Markdown following the template in Section 6.
12. **Mandatory Context Loading — Read `.agents/skills/` and Architecture Docs**:
   - **Read `.agents/skills/`**: Before executing any task, AI agents MUST inspect and read the relevant `SKILL.md` instructions within [`.agents/skills/`](.agents/skills/) (e.g., `flutter`, `mobile-expert`, `frontend-design`, `impeccable`, `aso`).
   - **Read Architecture Documentation**: AI agents MUST read and strictly adhere to the technical and architectural blueprints located in [`docs/`](docs/) (specifically [`docs/architecture.md`](docs/architecture.md), [`docs/database.md`](docs/database.md), and [`docs/backend.md`](docs/backend.md)) before designing or implementing features.

---

## 5. Agent Skills & Architecture Documentation Directory

### A. Skills (`.agents/skills/`)
Specialized domain skills are installed under `.agents/skills/`. Agents must consult and follow the respective `SKILL.md` before performing relevant tasks:

| Skill | Path | Description & Responsibilities |
| :--- | :--- | :--- |
| **`flutter`** | [`.agents/skills/flutter/SKILL.md`](.agents/skills/flutter/SKILL.md) | Dart 3, Riverpod 2.x, clean architecture, responsive widgets, declarative routing (GoRouter), profiling, and CLI tooling. |
| **`mobile-expert`** | [`.agents/skills/mobile-expert/SKILL.md`](.agents/skills/mobile-expert/SKILL.md) | Native platform integration (Android & iOS manifests, queries, intent filters), offline-first synchronization, SQLite persistence, memory & battery efficiency, security, and app release configs. |
| **`frontend-design`** | [`.agents/skills/frontend-design/SKILL.md`](.agents/skills/frontend-design/SKILL.md) | Intentional visual design, typography, layout rhythm, distinctive themes, and micro-interactions avoiding cookie-cutter UI defaults. |
| **`impeccable`** | [`.agents/skills/impeccable/SKILL.md`](.agents/skills/impeccable/SKILL.md) | Frontend craft, interface audits, responsive adaptation, light/dark theming, accessibility, error states, and UX copy clarity. |
| **`aso`** | [`.agents/skills/aso/SKILL.md`](.agents/skills/aso/SKILL.md) | App Store Optimization for Google Play and App Store listings: keyword research, conversion copy, localized metadata, and competitive audits. |

### B. Architecture Documentation (`docs/`)
Agents must read and follow the architectural designs and schemas in `docs/` before implementing or modifying systems:

| Document | Path | Scope & System Responsibilities |
| :--- | :--- | :--- |
| **`architecture.md`** | [`docs/architecture.md`](docs/architecture.md) | Complete application architecture, layer contracts, state management patterns, and screen/widget specifications. |
| **`database.md`** | [`docs/database.md`](docs/database.md) | SQLite schema, table structures, indices, version migrations, and offline persistence guarantees. |
| **`backend.md`** | [`docs/backend.md`](docs/backend.md) | Backend-agnostic adapter architecture, configuration, and the HTTP/Socket.IO adapter protocol with synchronization rules. |
| **`ASO_COPY_OPTIMIZATION.md`** | [`docs/ASO_COPY_OPTIMIZATION.md`](docs/ASO_COPY_OPTIMIZATION.md) | App Store and Google Play metadata, localized keywords, value propositions, and conversion copy. |

---

## 6. Pull Request Markdown Template

When writing a pull request upon request, use the following standardized Markdown format:

```markdown
# <type>(<scope>): <concise title>

## Overview
<High-level summary of changes and context for why this change was made.>

## Type of Change
- [ ] 🚀 New feature (`feat`)
- [ ] 🐛 Bug fix (`fix`)
- [ ] ♻️ Refactoring (`refactor`)
- [ ] ⚡ Performance improvement (`perf`)
- [ ] 📝 Documentation (`docs`)
- [ ] 🧪 Tests (`test`)
- [ ] 🔧 Build / CI (`build`, `ci`)

## Key Changes
- **<Component/Area>**: Description of implementation detail.
- **<Component/Area>**: Description of implementation detail.

## Architecture & Code Quality
- Clean Architecture compliance (Presentation -> Domain -> Data separation)
- Self-documenting code with zero comments in code files
- Adheres to git directives: zero `git add .`, zero `git commit`, and zero `git push` run by AI agents

## Testing & Coverage Verification
- [x] Unit & widget test suite passes: `flutter test`
- [x] 100.0% line coverage verified: `flutter test --coverage && dart run tool/verify_coverage.dart`
- [x] Static analysis clean (0 issues): `flutter analyze`
- [x] Formatting verified: `dart format --output=none --set-exit-if-changed .`

## Screenshots / Demos (if applicable)
<Before/After or feature preview>
```
