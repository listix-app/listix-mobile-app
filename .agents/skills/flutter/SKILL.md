---
name: flutter
description: >-
  Use this skill when developing, refactoring, profiling, or testing Flutter applications using Dart 3, Riverpod, clean architecture, responsive widgets, declarative routing, or Flutter CLI tooling.
---

# Flutter Expert Skill

This skill provides step-by-step guidance, architectural patterns, and performance conventions for building robust cross-platform applications with Flutter and Dart.

---

## 1. Flutter Rendering Pipeline & Widget Best Practices

### Understanding Widget, Element, and RenderObject Trees
- **Widget**: An immutable blueprint of the UI configuration. Recreated frequently at low CPU cost.
- **Element**: Manages the lifecycle and links the Widget to the underlying RenderObject.
- **RenderObject**: Handles layout calculations, sizing, hit testing, and painting. Expensive to instantiate.

### Rebuild Optimization Rules
1. **Use `const` Constructors Everywhere**:
   - `const` widgets are instantiated once at compile-time and are reused across rebuilds.
   - Flutter's reconciliation algorithm skips subtree comparisons when widget instances are identical.
2. **Decompose Granular Widgets**:
   - Extract small sub-widgets instead of writing giant monolithic `build()` methods or returning widgets from helper functions (`Widget _buildItem()`).
   - Smaller widget boundaries confine rebuilds to only the widgets that actually depend on changed state.
3. **Use `RepaintBoundary` for Complex or Frequently Animating Subtrees**:
   - Isolates the painting layer so that repainting child elements does not trigger repainting of the parent or sibling subtrees.
4. **Use `ListView.builder` / `SliverList` for Lists**:
   - Never use `SingleChildScrollView` + `Column` or `ListView(children: [...])` for dynamic or large datasets; always virtualize with lazy builders.

---

## 2. Riverpod State Management

### Provider Selection Guide
| Use Case | Recommended Provider |
| :--- | :--- |
| Read-only dependency / service injection (e.g. Dio, SharedPreferences) | `Provider<T>` |
| Synchronous state mutation (e.g. toggle theme, selected filter index) | `NotifierProvider<Notifier<T>, T>` |
| Asynchronous state & operations (e.g. API fetching, DB query, saving item) | `AsyncNotifierProvider<AsyncNotifier<T>, T>` |
| Read-only asynchronous streams (e.g. auth state changes, WebSocket stream) | `StreamProvider<T>` |

### Rules for Riverpod Consumers
- **`ref.watch()`**:
  - Use ONLY inside `build()` of a `ConsumerWidget` or `ConsumerStatefulWidget`.
  - Re-triggers the build method whenever the watched value updates.
  - Use `select((state) => state.specificProperty)` to rebuild only when a subset of state changes.
- **`ref.read()`**:
  - Use inside callbacks, event listeners, and button handlers (`onPressed: () => ref.read(...)`).
  - NEVER call `ref.read()` in `build()` because it does not subscribe to future updates.
- **`ref.listen()`**:
  - Use inside `build()` to trigger one-off side effects (e.g., displaying `SnackBar`, showing dialogs, navigating).

### Async State Handling
Always handle `AsyncValue` states cleanly in widgets:
```dart
ref.watch(myAsyncControllerProvider).when(
  data: (data) => ContentWidget(data),
  loading: () => const Center(child: CircularProgressIndicator.adaptive()),
  error: (err, stack) => ErrorDisplayWidget(error: err, onRetry: () => ref.invalidate(myAsyncControllerProvider)),
);
```

---

## 3. Dart 3 Capabilities & Patterns

Take full advantage of modern Dart 3 features:

### Sealed Classes for State & Failures
```dart
sealed class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
```

### Pattern Matching & Exhaustive Switch Expressions
```dart
Widget buildStatus(AuthState state) => switch (state) {
  AuthInitial() => const SizedBox.shrink(),
  AuthLoading() => const CircularProgressIndicator.adaptive(),
  AuthAuthenticated(:final user) => UserProfileView(user: user),
  AuthUnauthenticated() => const LoginView(),
  AuthFailure(:final message) => ErrorMessage(message),
};
```

### Records & Multiple Return Values
```dart
(double latitude, double longitude) getCoordinates() {
  return (37.7749, -122.4194);
}

final (lat, lng) = getCoordinates();
```

---

## 4. Navigation with GoRouter

1. **Declarative Routes**:
   - Define all routes centrally in `lib/src/routing/app_router.dart`.
   - Use typed routes or constants for path names.
2. **Redirect & Guards**:
   - Connect `redirect` to auth state providers using `ref.watch(authControllerProvider)`.
   - Ensure the router listens to auth changes via `refreshListenable`.
3. **Deep Linking**:
   - Set up route paths with clear URL parameter structures (`/items/:id`).

---

## 5. Testing Guidelines

### Unit Testing (Domain & Data Layers)
- Test Repositories, Data Sources, and Notifiers in isolation.
- Mock network and storage dependencies using `mocktail`.
```dart
test('getItems returns mapped domain entities on success', () async {
  final mockRemoteDataSource = MockItemsRemoteDataSource();
  final repository = ItemsRepositoryImpl(remoteDataSource: mockRemoteDataSource);

  when(() => mockRemoteDataSource.fetchItems())
      .thenAnswer((_) async => [ItemDto(id: '1', title: 'Test')]);

  final result = await repository.getItems();
  expect(result.first.id, '1');
  expect(result.first.title, 'Test');
});
```

### Widget Testing (Presentation Layer)
- Wrap widgets under test with `ProviderScope(overrides: [...])` to provide mock providers.
- Use `tester.pumpWidget()`, `tester.pumpAndSettle()`, and finders (`find.byType`, `find.text`).

---

## 6. Essential Flutter CLI Commands

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Format all Dart files
dart format .

# Run code generator (if build_runner is configured)
dart run build_runner build --delete-conflicting-outputs

# Run on connected device with verbose logs
flutter run -v

# Run with target device
flutter run -d chrome
flutter run -d linux
flutter run -d android
```
