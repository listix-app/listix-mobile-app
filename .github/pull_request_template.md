## 📝 Description

<!-- Briefly describe the purpose of this PR and what changes it introduces. -->

Closes # <!-- Link related issue if applicable, e.g., Closes #123 -->

---

## 📌 Type of Change

<!-- Mark with an 'x' the items that apply. -->

- [ ] ✨ **Feature** (non-breaking change which adds new functionality)
- [ ] 🐛 **Bug fix** (non-breaking change which fixes an issue)
- [ ] ♻️ **Refactor** (code cleanup or restructuring without changing behavior)
- [ ] ⚡ **Performance optimization** (improvements to rendering, memory, or battery efficiency)
- [ ] 🏗️ **Architecture / Technical Debt** (updates to domain models, repositories, or data sources)
- [ ] 👷 **CI/CD & DevOps** (GitHub Actions, build scripts, or deployment automation)
- [ ] 📚 **Documentation** (updates to README, AGENTS.md, or inline docstrings)
- [ ] 💥 **Breaking change** (fix or feature that causes existing functionality to fail or change behavior)

---

## 🏛️ Architectural Verification

<!-- Ensure this PR complies with the architectural rules in AGENTS.md. -->

- [ ] Follows **Feature-First** structure (`lib/src/features/<feature_name>/`).
- [ ] Clean separation between **Presentation**, **Domain**, and **Data** layers.
- [ ] **Riverpod**: State management correctly utilizes `Notifier` / `AsyncNotifier`; no direct API calls in UI widgets.
- [ ] **Repository Pattern**: Repository contracts defined in `domain/` and implemented in `data/`.
- [ ] **Data Sources**: Segregated into `RemoteDataSource` and/or `LocalDataSource` using DTOs.
- [ ] No `package:flutter` dependencies or serialization logic inside pure `domain/` entities.

---

## 📸 Screenshots / Demos (for UI changes)

| Before | After |
| :---: | :---: |
| <!-- Image / GIF / N/A --> | <!-- Image / GIF / N/A --> |

---

## ✅ Quality Checklist

<!-- Run these checks locally before opening the PR. -->

- [ ] Formatted code via `dart format .`
- [ ] Verified static analysis with `flutter analyze` (zero errors/warnings)
- [ ] Ran all unit and widget tests with `flutter test`
- [ ] Verified strict 100% test coverage via `flutter test --coverage test/all_tests_coverage.dart && dart run tool/verify_coverage.dart`
- [ ] Tested on at least one target device/platform (Android, Linux, Chrome, iOS)
- [ ] Updated or added relevant tests for new functionality
- [ ] Updated documentation or [AGENTS.md](AGENTS.md) if new conventions were introduced
