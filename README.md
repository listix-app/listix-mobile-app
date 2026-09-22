# Listix

[![CI](https://github.com/nmenag/listix/actions/workflows/ci.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/ci.yml)
[![PR Checks](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml/badge.svg)](https://github.com/nmenag/listix/actions/workflows/pr_checks.yml)

A modern, cross-platform Flutter application built with Clean Architecture, Feature-First modularization, Riverpod state management, and the Repository + DataSource pattern.

---

## 🏛️ Architecture Overview

Listix is structured around **Feature-First Clean Architecture**:

```
lib/src/features/<feature>/
├── presentation/   # UI widgets, screens, and Riverpod Notifiers
├── domain/         # Pure Dart entities, failure models, repository interfaces
└── data/           # Remote & Local data sources, DTOs, repository implementations
```

- **Feature-First**: Each business domain lives in an isolated feature folder.
- **Riverpod**: Handles unidirectional reactive state management and dependency injection.
- **Repository Pattern**: Mediates between domain logic and raw data retrieval.
- **Data Sources**: Segregates remote network communication (REST/Dio) from local storage (Cache/Database).

For complete architectural standards and conventions, see [AGENTS.md](AGENTS.md).

---

## 📋 Prerequisites

Ensure your development environment meets the following requirements:

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)**: `>= 3.13.3` (stable channel recommended)
- **Dart SDK**: Automatically bundled with Flutter SDK
- **Git**: For version control

### Platform-Specific Dependencies

- **Android**:
  - Android Studio with Android SDK (API 31+ or latest)
  - Android Virtual Device (AVD) or physical device with USB debugging enabled
  - Java Development Kit (JDK 17+)
- **Linux (Desktop)**:
  - `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev`
- **Web**:
  - Google Chrome browser
- **macOS / iOS** *(macOS host required)*:
  - Xcode 15+ and CocoaPods (`sudo gem install cocoapods`)

---

## 🚀 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nmenag/listix.git
   cd listix
   ```

2. **Verify your Flutter installation:**
   ```bash
   flutter doctor
   ```
   Resolve any reported issues before proceeding.

3. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

4. *(Optional)* **Run code generator** (when code generation packages like `freezed` or `riverpod_generator` are present):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## 📱 Running the Application

### 1. View Connected Devices
Check which physical devices, emulators, or desktop platforms are available:
```bash
flutter devices
```

### 2. Run on Default Device
To launch on the first available connected device:
```bash
flutter run
```

### 3. Run on a Specific Target
Specify the target device using the `-d` flag:

- **Android Device / Emulator**:
  ```bash
  flutter run -d android
  # Or target a specific device ID:
  flutter run -d ZY22FZ5M65
  ```

- **Linux Desktop**:
  ```bash
  flutter run -d linux
  ```

- **Web (Chrome)**:
  ```bash
  flutter run -d chrome
  ```

- **iOS Simulator / Device** *(macOS only)*:
  ```bash
  flutter run -d ios
  ```

### 4. Run Modes

- **Debug Mode** (default): Full debugging support with Hot Reload (`r`) and Hot Restart (`R`).
  ```bash
  flutter run --debug
  ```
- **Profile Mode**: High-performance mode for analyzing CPU, memory, and frame rates via Flutter DevTools.
  ```bash
  flutter run --profile
  ```
- **Release Mode**: Optimized production binary without debugging overhead.
  ```bash
  flutter run --release
  ```

---

## 📦 Building Release Artifacts

To compile distribution binaries for specific platforms:

- **Android APK**:
  ```bash
  flutter build apk --release
  ```
- **Android App Bundle (for Google Play)**:
  ```bash
  flutter build appbundle --release
  ```
- **Linux Desktop**:
  ```bash
  flutter build linux --release
  ```
- **Web**:
  ```bash
  flutter build web --release
  ```
- **iOS IPA** *(macOS only)*:
  ```bash
  flutter build ipa --release
  ```

---

## 🧪 Testing & Code Quality

Maintain codebase health using the following commands:

- **Analyze static code & lints:**
  ```bash
  flutter analyze
  ```

- **Format Dart code:**
  ```bash
  dart format .
  ```

- **Run all unit & widget tests:**
  ```bash
  flutter test
  ```

- **Generate test coverage report:**
  ```bash
  flutter test --coverage
  ```

- **Validate commit messages locally:**
  ```bash
  echo "feat: my commit message" | npx @commitlint/cli
  ```

---

## 🔄 Continuous Integration & PR Quality Gates

Automated checks are powered by GitHub Actions:

### 1. Build & Test Pipeline ([`.github/workflows/ci.yml`](.github/workflows/ci.yml))
Triggered on every push and pull request to `main` and `master`:
- **Lint & Static Analysis**: Enforces `dart format` and checks for zero static analysis issues via `flutter analyze`.
- **Unit & Widget Tests**: Runs the test suite with coverage (`flutter test --coverage`) and publishes artifacts.

### 2. Pull Request Quality Checks ([`.github/workflows/pr_checks.yml`](.github/workflows/pr_checks.yml))
Triggered on pull request events (`opened`, `edited`, `synchronize`, `reopened`):
- **PR Title Validation**: Verifies that the PR title adheres to [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat: ...`, `fix(auth): ...`).
- **Commit Linting**: Validates all commit messages within the PR against Conventional Commits using [commitlint](commitlint.config.js).
- **PR Size Check**:
  - Calculates non-generated, reviewed lines changed.
  - Automatically tags the PR with size labels (`size/XS`, `size/S`, `size/M`, `size/L`, `size/XL`, `size/XXL`).
  - Warns authors if the PR exceeds 500 lines to encourage smaller, more reviewable submissions.

---

## 🤖 Agent Skills & AI Directives

This project includes agent skills located in `.agents/skills/`:
- **[`mobile-expert`](.agents/skills/mobile-expert/SKILL.md)**: Mobile platform architecture, security, offline sync, memory, and store release checklists.
- **[`flutter`](.agents/skills/flutter/SKILL.md)**: Flutter rendering pipeline, Riverpod patterns, Dart 3 features, and testing guides.
- **[`AGENTS.md`](AGENTS.md)**: Comprehensive architectural rules for Feature-First + Riverpod + Repository + DataSource patterns.
