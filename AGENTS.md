# AGENTS.md

> Architectural Guidelines and Operational Directives for AI Agents working on **Listix**.

This document outlines the mandatory engineering standards, architectural patterns, and project conventions for all AI agents and contributors working in this codebase.

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
│ (REST / GraphQL / Supabase)        (SQLite / Hive / Prefs)
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
5. **Testing Requirements**:
   - Data sources: test HTTP/database failure modes and successful JSON decoding.
   - Repositories: test offline caching fallback, DTO-to-entity mapping, and error translation.
   - Controllers: test state transitions (`loading` -> `data` / `error`).
   - Widgets: test UI rendering with `ProviderScope(overrides: [...])`.
6. **Code Cleanliness & Analysis**:
   - Run `flutter analyze` after making changes and resolve all errors and warnings.
   - Follow Flutter and Dart formatting guidelines (`dart format .`).
7. **Commit & PR Conventions**:
   - Commits and PR titles must adhere to **Conventional Commits**: `<type>(<optional scope>): <description>`.
   - Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
   - Keep pull requests small and focused (< 500 lines of reviewed changes) to facilitate rapid, effective code reviews.
