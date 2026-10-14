import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract interface class NotificationService {
  Future<bool> initialize();
  Future<bool> requestPermissions();
  Future<bool> scheduleWeeklyReminder({
    required String title,
    required String body,
    int dayOfWeek = DateTime.sunday,
    int hour = 10,
    int minute = 0,
  });
  Future<void> cancelWeeklyReminder();
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  });
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final bool _isAndroid;
  bool _isInitialized = false;

  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    bool? isAndroid,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _isAndroid = isAndroid ?? true;

  static const int weeklyNotificationId = 1001;
  static const String channelId = 'weekly_reminder_channel';
  static const String channelName = 'Weekly Shopping Reminder';
  static const String channelDescription =
      'Weekly reminder to plan and organize your shopping lists.';

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );

      const initSettings = InitializationSettings(android: androidSettings);

      final result = await _plugin.initialize(settings: initSettings);
      _isInitialized = result ?? true;
      return _isInitialized;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (_isAndroid) {
      final androidPlatform = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted =
          await androidPlatform?.requestNotificationsPermission() ?? false;
      return granted;
    }

    return true;
  }

  tz.TZDateTime calculateNextScheduledDate(
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  @override
  Future<bool> scheduleWeeklyReminder({
    required String title,
    required String body,
    int dayOfWeek = DateTime.sunday,
    int hour = 10,
    int minute = 0,
  }) async {
    await initialize();

    final scheduledDate = calculateNextScheduledDate(dayOfWeek, hour, minute);

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        id: weeklyNotificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> cancelWeeklyReminder() async {
    await _plugin.cancel(id: weeklyNotificationId);
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final initialized = await initialize();
      if (!initialized) return;

      const androidDetails = AndroidNotificationDetails(
        'items_notification_channel',
        'Listix Item Updates',
        channelDescription: 'Notifications for items added to shopping lists.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {}
  }
}
