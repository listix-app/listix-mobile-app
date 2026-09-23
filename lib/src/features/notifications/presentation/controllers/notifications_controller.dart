import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

class NotificationsController extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  Future<bool> toggleWeeklyNotifications({
    required bool enabled,
    required String title,
    required String body,
  }) async {
    final service = ref.read(notificationServiceProvider);

    if (enabled) {
      await service.requestPermissions();
      final scheduled = await service.scheduleWeeklyReminder(
        title: title,
        body: body,
      );
      state = scheduled;
      return scheduled;
    } else {
      await service.cancelWeeklyReminder();
      state = false;
      return true;
    }
  }

  void setEnabledState(bool enabled) {
    state = enabled;
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, bool>(
      NotificationsController.new,
    );
