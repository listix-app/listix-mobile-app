import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/theme/theme_controller.dart';
import 'package:listix/src/features/notifications/data/services/notification_service.dart';
import 'package:listix/src/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:listix/src/features/settings/presentation/screens/settings_screen.dart';

class _SettingsTestNotificationService implements NotificationService {
  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> scheduleWeeklyReminder({
    required String title,
    required String body,
    int dayOfWeek = DateTime.sunday,
    int hour = 10,
    int minute = 0,
  }) async => true;

  @override
  Future<void> cancelWeeklyReminder() async {}
}

void main() {
  group('ThemeModeController Unit Tests', () {
    test('starts with system and toggles modes correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeControllerProvider), ThemeMode.system);

      container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeControllerProvider), ThemeMode.dark);

      container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(ThemeMode.light);
      expect(container.read(themeModeControllerProvider), ThemeMode.light);

      container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(ThemeMode.system);
      expect(container.read(themeModeControllerProvider), ThemeMode.system);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all sections and interactions work properly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(
              _SettingsTestNotificationService(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Listix'), findsOneWidget);

      expect(find.text('TEMA'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();

      expect(find.text('IDIOMA'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('weekly_notification_switch')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Terms of Service'), 300);
      expect(find.text('100% Offline-First'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Español'), -300);
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();
      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('SettingsScreen pop button taps without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Open Settings'), findsOneWidget);
    });
  });
}
