---
name: mobile-expert
description: >-
  Use this skill when designing, reviewing, debugging, or optimizing mobile application architecture, native platform integration (Android & iOS), offline-first synchronization, mobile security, memory and battery efficiency, app permissions, background execution, or app store release configuration.
---

# Mobile Expert Skill

This skill provides comprehensive instructions and best practices for developing, auditing, and optimizing production-grade mobile applications across Android and iOS platforms.

---

## 1. Core Mobile Constraints & Philosophy

Mobile environments differ fundamentally from desktop and web environments:
- **Strict Resource Constraints**: Operating systems aggressively terminate processes that consume excessive memory or hold background locks.
- **Unreliable Connectivity**: Network connectivity fluctuates between high-speed Wi-Fi, cellular (4G/5G), edge, and complete disconnection.
- **Asynchronous Lifecycles**: The OS can suspend or kill an app at any time when in the background to reclaim memory.
- **Hardware Diversity**: Varying screen sizes, aspect ratios, refresh rates (60Hz to 120Hz ProMotion), notch/island cutouts, and foldable screens.

---

## 2. Offline-First & Data Synchronization

When implementing offline-first architecture:

1. **Local-First Writes**:
   - Write immediately to the local persistent store (SQLite, Drift, Hive, Realm).
   - Reflect changes in the UI optimistically before network confirmation.
   - Queue mutations in a persistent pending actions queue.

2. **Sync & Conflict Resolution**:
   - Implement conflict resolution strategies:
     - **Client-Wins / Server-Wins**: Suitable for simple preference changes.
     - **Timestamp / Last-Write-Wins (LWW)**: Require synchronized UTC clocks.
     - **Field-Level Merging**: Merge distinct updated fields rather than replacing entire entities.
   - Attach sync metadata to records: `sync_status` (`synced`, `pending_create`, `pending_update`, `pending_delete`), `local_updated_at`, `server_updated_at`.

3. **Background Syncing**:
   - Leverage OS-compliant background mechanisms (Android `WorkManager`, iOS `BGAppRefreshTask` / `BGProcessingTask`).
   - Respect battery and metered network constraints (`NetworkType.UNMETERED`, `requiresCharging`).

---

## 3. Performance & Memory Management

### Frame Budget & Jank Prevention
- **Target**: Maintain a consistent 60 FPS (16.6ms per frame) or 120 FPS (8.3ms per frame).
- Keep heavy computational tasks off the main thread / UI isolate:
  - JSON decoding for large payloads (`compute()` or dedicated background worker).
  - Image manipulation and cryptography.
  - Complex database migrations or bulk inserts.

### Memory Leak Prevention
- Always dispose resources:
  - Cancel Stream subscriptions (`StreamSubscription.cancel()`).
  - Dispose controllers (`AnimationController`, `TextEditingController`, `ScrollController`, `PageController`).
  - Remove event listeners in teardown/dispose hooks.
- Avoid holding strong references to `BuildContext` across asynchronous gaps.
- Cache and downsample images according to display size rather than loading raw camera/network resolutions into memory.

---

## 4. Mobile Security & Data Protection

1. **Secure Storage**:
   - Never store sensitive data (tokens, API keys, credentials, PII) in unencrypted storage (plain `SharedPreferences` or `UserDefaults`).
   - Use hardware-backed secure storage:
     - **Android**: Android Keystore with `EncryptedSharedPreferences`.
     - **iOS**: iOS Keychain Services (`kSecClassGenericPassword`, `kSecAttrAccessibleAfterFirstUnlock`).
2. **Network Security**:
   - Enforce HTTPS / TLS 1.3.
   - Implement SSL Pinning for high-security endpoints to prevent Man-in-the-Middle (MitM) attacks.
   - Sanitize all outbound and inbound network logs in release builds (strip auth headers and passwords).
3. **App Tampering & Obfuscation**:
   - Enable code shrinking and obfuscation:
     - **Android**: R8 / ProGuard rules (`minifyEnabled true`, `shrinkResources true`).
     - **iOS**: Strip debug symbols, enable bitcode/symbol visibility controls.
   - Disable debugging and root/jailbreak detection where required by security policy.

---

## 5. Platform Integration (Android & iOS)

### App Lifecycle Handling
Monitor app lifecycle transitions (`resumed`, `inactive`, `paused`, `detached`):
- **On Pause / Background**: Pause video playback, stop camera previews, commit unsaved changes to local storage, invalidate transient timers.
- **On Resume**: Check authentication session validity, refresh stale data, check for app update requirements.

### Runtime Permissions
- Request permissions **in context**, not upon initial app launch (e.g., request camera only when user taps "Take Photo").
- Handle all permission states:
  - `Granted`: Proceed with action.
  - `Denied`: Display an explanation of why the feature requires this permission.
  - `Permanently Denied`: Direct user gracefully to App System Settings.

### Deep Linking & Universal Links
- Android: Implement **App Links** (`assetlinks.json` verification on domain).
- iOS: Implement **Universal Links** (`apple-app-site-association` on domain).
- Ensure routing can handle initial URI and background incoming URIs cleanly.

---

## 6. App Store Preparation & Release Engineering

1. **Android Deployment**:
   - Build Android App Bundle (`.aab`) rather than APK for dynamic feature delivery and size optimization.
   - Set up upload keystore and protect `key.properties`.
   - Set proper `targetSdkVersion` aligned with Google Play's latest requirements.
2. **iOS Deployment**:
   - Configure Apple Developer signing profiles and distribution certificates.
   - Ensure privacy manifest (`PrivacyInfo.xcprivacy`) declarations match all SDKs used.
   - Validate required `Info.plist` usage descriptions (e.g., `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`).
3. **Automated CI/CD**:
   - Use Fastlane or GitHub Actions for automated linting, test suites, version bumping, building, and internal track distribution (Firebase App Distribution, TestFlight, Play Console Internal).

---

## 7. Mobile Expert Verification Checklist

Before approving any mobile feature or architecture change, verify:
- [ ] Are sensitive tokens/passwords stored using hardware-backed secure storage?
- [ ] Does the app function properly when network connectivity is lost?
- [ ] Are all controllers, subscriptions, and listeners properly disposed?
- [ ] Is heavy data processing moved off the UI thread / isolate?
- [ ] Are permissions requested contextually with proper fallback when denied?
- [ ] Does UI adapt cleanly to small screens, large tablets, and safe area notches?
- [ ] Does the app properly handle backgrounding and state restoration without crashing?
