import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/app.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/core/widgets/listix_logo.dart';
import 'package:listix/src/features/about/presentation/screens/about_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    try {
      if (databaseFactory != databaseFactoryFfi) {
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {
      databaseFactory = databaseFactoryFfi;
    }
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
  });

  group('Localization & AboutScreen Tests', () {
    test('AppStrings contains Spanish and English translations', () {
      const es = AppStrings(AppLanguage.es);
      const en = AppStrings(AppLanguage.en);

      expect(es.myLists, 'Mis Listas');
      expect(en.myLists, 'My Lists');

      expect(es.privacyPolicy, 'Política de Privacidad');
      expect(en.privacyPolicy, 'Privacy Policy');

      expect(es.newList, 'Nueva lista');
      expect(en.newList, 'New list');

      expect(es.noItemsBadge, 'Sin items');
      expect(en.noItemsBadge, 'No items');
      expect(es.allDoneBadge, 'Todo listo ✓');
      expect(en.allDoneBadge, 'All done ✓');
      expect(es.pendingBadge('1/2'), '1/2 pendientes');
      expect(en.pendingBadge('1/2'), '1/2 pending');
      expect(
        es.inviteSent('maria@test.com'),
        'Invitación enviada a maria@test.com',
      );
      expect(
        en.inviteSent('maria@test.com'),
        'Invitation sent to maria@test.com',
      );
    });

    testWidgets('ListixLogo renders correctly with and without wordmark', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ListixLogo(size: 40),
                ListixLogo(size: 40, showWordmark: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ListixLogo), findsNWidgets(2));
      expect(find.text('Listix', findRichText: true), findsOneWidget);
    });

    testWidgets(
      'AboutScreen renders app info, privacy policy, and language switcher',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: AboutScreen())),
        );

        // Verify app identity & version
        expect(find.text('Listix'), findsOneWidget);
        expect(find.textContaining('1.0.0'), findsOneWidget);

        // Verify sections
        expect(find.text('Offline-First'), findsOneWidget);
        expect(find.text('Pol\u00edtica de Privacidad'), findsOneWidget);
        expect(find.text('T\u00e9rminos del Servicio'), findsOneWidget);

        // Verify language switcher buttons
        expect(find.text('Espa\u00f1ol'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);

        // Switch language to English
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        // Verify strings updated to English
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('About Listix'), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen allows navigating to AboutScreen and shows Listix logo',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.runAsync(() async {
          await AppDatabase.instance.database;
        });

        await tester.pumpWidget(const ProviderScope(child: ListixApp()));

        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        // Verify logo in AppBar
        expect(find.byType(ListixLogo), findsOneWidget);

        // Tap info/about icon
        final infoIconFinder = find.byIcon(Icons.info_outline_rounded);
        expect(infoIconFinder, findsOneWidget);
        await tester.tap(infoIconFinder);
        await tester.pumpAndSettle();

        // Verify we navigated to AboutScreen
        expect(find.byType(AboutScreen), findsOneWidget);
        expect(find.text('Pol\u00edtica de Privacidad'), findsOneWidget);
      },
    );
  });
}
