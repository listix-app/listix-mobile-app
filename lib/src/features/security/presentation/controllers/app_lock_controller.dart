import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../data/services/app_lock_service.dart';

@immutable
class AppLockState {
  final bool isEnabled;
  final bool isLocked;
  final bool isAuthenticating;

  const AppLockState({
    this.isEnabled = false,
    this.isLocked = false,
    this.isAuthenticating = false,
  });

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? isAuthenticating,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLockState &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          isLocked == other.isLocked &&
          isAuthenticating == other.isAuthenticating;

  @override
  int get hashCode => Object.hash(isEnabled, isLocked, isAuthenticating);
}

class AppLockController extends Notifier<AppLockState> {
  final AppDatabase _db;
  bool _isDisposed = false;
  DateTime? _pausedAt;
  static const String settingKey = 'app_lock_enabled';
  static const Duration backgroundGracePeriod = Duration(minutes: 1);

  AppLockController([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  @override
  AppLockState build() {
    _isDisposed = false;
    _pausedAt = null;
    ref.onDispose(() => _isDisposed = true);
    _loadFromDatabase();
    return const AppLockState();
  }

  Future<void> _loadFromDatabase() async {
    final value = await _db.getSetting(settingKey);
    final enabled = value == '1';
    if (!_isDisposed) {
      state = state.copyWith(isEnabled: enabled, isLocked: enabled);
    }
  }

  Future<bool> unlock(String localizedReason) async {
    if (!state.isEnabled || !state.isLocked || state.isAuthenticating) {
      return true;
    }

    state = state.copyWith(isAuthenticating: true);
    final service = ref.read(appLockServiceProvider);
    final authenticated = await service.authenticate(
      localizedReason: localizedReason,
    );
    if (_isDisposed) return authenticated;

    if (authenticated) {
      _pausedAt = null;
      state = state.copyWith(isLocked: false, isAuthenticating: false);
      return true;
    } else {
      state = state.copyWith(isAuthenticating: false);
      return false;
    }
  }

  Future<bool> toggleAppLock({
    required bool enabled,
    required String localizedReason,
  }) async {
    final service = ref.read(appLockServiceProvider);
    final authenticated = await service.authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) return false;

    await _db.setSetting(settingKey, enabled ? '1' : '0');
    if (!_isDisposed) {
      _pausedAt = null;
      state = state.copyWith(isEnabled: enabled, isLocked: false);
    }
    return true;
  }

  void lock() {
    if (state.isEnabled && !state.isLocked) {
      _pausedAt = null;
      state = state.copyWith(isLocked: true);
    }
  }

  void onAppBackgrounded({DateTime? now}) {
    if (state.isEnabled && !state.isLocked && !state.isAuthenticating) {
      _pausedAt ??= now ?? DateTime.now();
    }
  }

  void onAppResumed({DateTime? now}) {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null &&
        state.isEnabled &&
        !state.isLocked &&
        !state.isAuthenticating) {
      final currentTime = now ?? DateTime.now();
      if (currentTime.difference(pausedAt) >= backgroundGracePeriod) {
        lock();
      }
    }
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockState>(() {
      return AppLockController();
    });
