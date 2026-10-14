import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../data/services/notification_service.dart';

@immutable
class NotificationsState {
  final bool isEnabled;
  final int hour;
  final int minute;

  const NotificationsState({
    this.isEnabled = false,
    this.hour = 10,
    this.minute = 0,
  });

  NotificationsState copyWith({bool? isEnabled, int? hour, int? minute}) {
    return NotificationsState(
      isEnabled: isEnabled ?? this.isEnabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationsState &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => Object.hash(isEnabled, hour, minute);
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

class NotificationsController extends Notifier<NotificationsState> {
  final AppDatabase _db;
  bool _isDisposed = false;
  bool _isModified = false;

  NotificationsController([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  @override
  NotificationsState build() {
    _isDisposed = false;
    _isModified = false;
    ref.onDispose(() => _isDisposed = true);
    _loadFromDatabase();
    return const NotificationsState();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final enabledStr = await _db.getSetting('notification_enabled');
      if (_isDisposed || _isModified) return;
      final hourStr = await _db.getSetting('notification_hour');
      if (_isDisposed || _isModified) return;
      final minuteStr = await _db.getSetting('notification_minute');
      if (_isDisposed || _isModified) return;

      if (enabledStr != null || hourStr != null || minuteStr != null) {
        state = state.copyWith(
          isEnabled: enabledStr != null ? enabledStr == 'true' : null,
          hour: hourStr != null ? int.tryParse(hourStr) : null,
          minute: minuteStr != null ? int.tryParse(minuteStr) : null,
        );
      }
    } catch (_) {}
  }

  Future<bool> toggleNotifications(bool enabled) async {
    _isModified = true;
    final service = ref.read(notificationServiceProvider);
    if (enabled) {
      await service.requestPermissions();
      state = state.copyWith(isEnabled: true);
      try {
        await _db.setSetting('notification_enabled', 'true');
      } catch (_) {}
      return true;
    } else {
      await service.cancelWeeklyReminder();
      state = state.copyWith(isEnabled: false);
      try {
        await _db.setSetting('notification_enabled', 'false');
      } catch (_) {}
      return true;
    }
  }

  Future<bool> toggleWeeklyNotifications({
    required bool enabled,
    required String title,
    required String body,
  }) async {
    _isModified = true;
    final service = ref.read(notificationServiceProvider);
    if (enabled) {
      await service.requestPermissions();
      final scheduled = await service.scheduleWeeklyReminder(
        title: title,
        body: body,
        hour: state.hour,
        minute: state.minute,
      );
      state = state.copyWith(isEnabled: scheduled);
      try {
        await _db.setSetting('notification_enabled', scheduled.toString());
      } catch (_) {}
      return scheduled;
    } else {
      await service.cancelWeeklyReminder();
      state = state.copyWith(isEnabled: false);
      try {
        await _db.setSetting('notification_enabled', 'false');
      } catch (_) {}
      return true;
    }
  }

  Future<bool> setReminderTime({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    _isModified = true;
    final service = ref.read(notificationServiceProvider);
    state = state.copyWith(hour: hour, minute: minute);
    try {
      await _db.setSetting('notification_hour', hour.toString());
      await _db.setSetting('notification_minute', minute.toString());
    } catch (_) {}
    if (state.isEnabled) {
      await service.scheduleWeeklyReminder(
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      );
    }
    return true;
  }

  void setEnabledState(bool enabled) {
    _isModified = true;
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> showItemNotification({
    required String listName,
    required String itemTitle,
  }) async {
    final service = ref.read(notificationServiceProvider);
    await service.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: listName,
      body: 'Elemento añadido: $itemTitle',
    );
  }

  Future<void> showSharedItemNotification({
    required String listName,
    required String itemTitle,
    required String senderName,
  }) async {
    final service = ref.read(notificationServiceProvider);
    await service.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: listName,
      body: '$senderName añadió: $itemTitle',
    );
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );
