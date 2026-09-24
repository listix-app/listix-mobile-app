import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/notifications/data/services/notification_service.dart';
import 'package:listix/src/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationService implements NotificationService {
  bool initResult = true;
  bool permissionResult = true;
  bool scheduleResult = true;
  int scheduleCallCount = 0;
  int cancelCallCount = 0;
  String? lastTitle;
  String? lastBody;

  @override
  Future<bool> initialize() async => initResult;

  @override
  Future<bool> requestPermissions() async => permissionResult;

  @override
  Future<bool> scheduleWeeklyReminder({
    required String title,
    required String body,
    int dayOfWeek = DateTime.sunday,
    int hour = 10,
    int minute = 0,
  }) async {
    scheduleCallCount++;
    lastTitle = title;
    lastBody = body;
    return scheduleResult;
  }

  @override
  Future<void> cancelWeeklyReminder() async {
    cancelCallCount++;
  }
}

class MockAndroidFlutterLocalNotificationsPlugin
    implements AndroidFlutterLocalNotificationsPlugin {
  @override
  Future<bool?> requestNotificationsPermission() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocalNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  bool initializeSuccess = true;
  int cancelCallCount = 0;
  int scheduleCallCount = 0;
  bool shouldThrowOnSchedule = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    return initializeSuccess;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelCallCount++;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    if (shouldThrowOnSchedule) {
      throw Exception('Schedule failed');
    }
    scheduleCallCount++;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return MockAndroidFlutterLocalNotificationsPlugin() as T;
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
    await AppDatabase.instance.database;
  });
  group('LocalNotificationService Tests', () {
    late MockLocalNotificationsPlugin mockPlugin;
    late LocalNotificationService service;

    setUp(() {
      tz.initializeTimeZones();
      mockPlugin = MockLocalNotificationsPlugin();
      service = LocalNotificationService(plugin: mockPlugin);
    });

    test('initialize initializes plugin and returns true', () async {
      final result = await service.initialize();
      expect(result, isTrue);

      final secondResult = await service.initialize();
      expect(secondResult, isTrue);
    });

    test(
      'calculateNextScheduledDate returns future date matching target weekday',
      () {
        final scheduled = service.calculateNextScheduledDate(
          DateTime.sunday,
          10,
          0,
        );
        expect(scheduled.weekday, DateTime.sunday);
        expect(scheduled.hour, 10);
        expect(scheduled.minute, 0);
        expect(scheduled.isAfter(tz.TZDateTime.now(tz.local)), isTrue);
      },
    );

    test(
      'scheduleWeeklyReminder initializes and schedules notification',
      () async {
        final scheduled = await service.scheduleWeeklyReminder(
          title: '¡Hora de organizar tus compras!',
          body: 'Revisa tus listas pendientes',
        );
        expect(scheduled, isTrue);
        expect(mockPlugin.scheduleCallCount, 1);
      },
    );

    test('scheduleWeeklyReminder returns false on exception', () async {
      mockPlugin.shouldThrowOnSchedule = true;
      final scheduled = await service.scheduleWeeklyReminder(
        title: 'Error list',
        body: 'Error body',
      );
      expect(scheduled, isFalse);
    });

    test('cancelWeeklyReminder calls cancel on plugin', () async {
      await service.cancelWeeklyReminder();
      expect(mockPlugin.cancelCallCount, 1);
    });

    test(
      'requestPermissions handles android and non-android platforms',
      () async {
        final defaultResult = await service.requestPermissions();
        expect(defaultResult, isA<bool>());

        final androidService = LocalNotificationService(
          plugin: mockPlugin,
          isAndroid: true,
        );
        final androidResult = await androidService.requestPermissions();
        expect(androidResult, isTrue);

        final nonAndroidService = LocalNotificationService(
          plugin: mockPlugin,
          isAndroid: false,
        );
        final nonAndroidResult = await nonAndroidService.requestPermissions();
        expect(nonAndroidResult, isTrue);
      },
    );

    test('default constructor creates instance', () {
      final defaultService = LocalNotificationService();
      expect(defaultService, isNotNull);
    });
  });

  group('NotificationsController Tests', () {
    late FakeNotificationService fakeService;

    setUp(() {
      fakeService = FakeNotificationService();
    });

    test('build initializes false by default', () {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final state = container.read(notificationsControllerProvider);
      expect(state.isEnabled, isFalse);
      expect(fakeService.scheduleCallCount, 0);
    });

    test(
      'toggleWeeklyNotifications to true requests permissions and schedules reminder',
      () async {
        final container = ProviderContainer(
          overrides: [
            notificationServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          notificationsControllerProvider.notifier,
        );
        final success = await notifier.toggleWeeklyNotifications(
          enabled: true,
          title: 'Recordatorio',
          body: 'Revisa tus listas',
        );

        expect(success, isTrue);
        expect(
          container.read(notificationsControllerProvider).isEnabled,
          isTrue,
        );
        expect(fakeService.scheduleCallCount, 1);
        expect(fakeService.lastTitle, 'Recordatorio');
        expect(fakeService.lastBody, 'Revisa tus listas');
      },
    );

    test('toggleWeeklyNotifications to false cancels reminder', () async {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationsControllerProvider.notifier);
      notifier.setEnabledState(true);
      expect(container.read(notificationsControllerProvider).isEnabled, isTrue);

      final success = await notifier.toggleWeeklyNotifications(
        enabled: false,
        title: 'Recordatorio',
        body: 'Revisa tus listas',
      );

      expect(success, isTrue);
      expect(
        container.read(notificationsControllerProvider).isEnabled,
        isFalse,
      );
      expect(fakeService.cancelCallCount, 1);
    });

    test('setReminderTime updates time and reschedules if enabled', () async {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationsControllerProvider.notifier);
      await notifier.toggleWeeklyNotifications(
        enabled: true,
        title: 'Title',
        body: 'Body',
      );
      expect(fakeService.scheduleCallCount, 1);

      await notifier.setReminderTime(
        hour: 15,
        minute: 30,
        title: 'New Title',
        body: 'New Body',
      );
      final state = container.read(notificationsControllerProvider);
      expect(state.hour, 15);
      expect(state.minute, 30);
      expect(fakeService.scheduleCallCount, 2);
    });

    test(
      'NotificationsController loads persisted settings from database',
      () async {
        await AppDatabase.instance.setSetting('notification_enabled', 'true');
        await AppDatabase.instance.setSetting('notification_hour', '14');
        await AppDatabase.instance.setSetting('notification_minute', '45');

        final controller = NotificationsController();
        final container = ProviderContainer(
          overrides: [
            notificationsControllerProvider.overrideWith(() => controller),
            notificationServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        container.read(notificationsControllerProvider);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final state = container.read(notificationsControllerProvider);
        expect(state.isEnabled, isTrue);
        expect(state.hour, 14);
        expect(state.minute, 45);
      },
    );

    test('NotificationsState copyWith, equals and hashCode', () {
      const state1 = NotificationsState(isEnabled: true, hour: 11, minute: 15);
      final state2 = state1.copyWith(minute: 20);
      expect(state2.minute, 20);
      expect(state2.hour, 11);
      expect(state2.isEnabled, isTrue);

      final state3 = state2.copyWith(hour: 12, isEnabled: false);
      expect(state3.hour, 12);
      expect(state3.isEnabled, isFalse);

      const state4 = NotificationsState(isEnabled: true, hour: 11, minute: 15);
      expect(state1, equals(state4));
      expect(state1.hashCode, state4.hashCode);
      expect(state1 == state2, isFalse);
    });

    test(
      'default notificationServiceProvider creates LocalNotificationService',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(notificationServiceProvider);
        expect(service, isA<LocalNotificationService>());
      },
    );
  });
}
