import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/theme/theme_controller.dart';
import 'package:listix/src/features/settings/presentation/screens/settings_screen.dart';

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
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Listix'), findsOneWidget);

      // Theme options
      expect(find.text('TEMA'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);

      // Tap Dark theme
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      // Tap Light theme
      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();

      // Language options
      expect(find.text('IDIOMA'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Tap English language
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Content now in English
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('100% Offline-First'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);

      // Switch back to Spanish
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
