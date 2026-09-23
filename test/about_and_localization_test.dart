import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/app.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/core/widgets/listix_logo.dart';
import 'package:listix/src/features/about/presentation/screens/about_screen.dart';
import 'package:listix/src/features/settings/presentation/screens/settings_screen.dart';
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
    test('AppLocalizations & AppStrings provide Spanish and English', () {
      final es = AppStrings(AppLanguage.es);
      final en = AppStrings(AppLanguage.en);

      expect(es.myLists, 'Mis Listas');
      expect(en.myLists, 'My Lists');

      expect(es.privacyPolicy, 'Política de Privacidad');
      expect(en.privacyPolicy, 'Privacy Policy');

      expect(es.newList, 'Nueva lista');
      expect(en.newList, 'New list');

      expect(es.ownerBadge, 'Dueño');
      expect(en.ownerBadge, 'Owner');

      expect(es.removeCollaborator, 'Quitar colaborador');
      expect(en.removeCollaborator, 'Remove collaborator');

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

      expect(es.themeTitle, 'Tema');
      expect(en.themeTitle, 'Appearance');
      expect(es.themeSystem, 'Sistema');
      expect(en.themeSystem, 'System');
      expect(es.themeLight, 'Claro');
      expect(en.themeLight, 'Light');
      expect(es.themeDark, 'Oscuro');
      expect(en.themeDark, 'Dark');

      expect(es.shareWhatsApp, 'Compartir por WhatsApp');
      expect(en.shareWhatsApp, 'Share via WhatsApp');
      expect(es.shareGmail, 'Compartir por Gmail');
      expect(en.shareGmail, 'Share via Gmail');
      expect(es.copyListText, 'Copiar texto de la lista');
      expect(en.copyListText, 'Copy list text');
      expect(es.listCopied, '¡Lista copiada al portapapeles!');
      expect(en.listCopied, 'List copied to clipboard!');
      expect(es.shareSubject('Compras'), 'Listix: Compras');
      expect(en.shareSubject('Groceries'), 'Listix: Groceries');
      expect(es.sharedWithListix, contains('Listix'));
      expect(en.sharedWithListix, contains('Listix'));
      expect(es.offlineNoticeDesc, contains('SQLite'));
      expect(es.offlineNoticeDesc, contains('SQLite'));

      expect(es.versionLabel('1.0.0', '1'), contains('1.0.0'));
      expect(en.versionLabel('1.0.0', '1'), contains('1.0.0'));

      expect(es.copyrightFooter(2026), contains('2026'));
      expect(en.copyrightFooter(2026), contains('2026'));

      expect(es.errorPrefix('Failed'), 'Error: Failed');
      expect(en.errorPrefix('Failed'), 'Error: Failed');

      final directEs = lookupAppLocalizations(const Locale('es'));
      final directEn = lookupAppLocalizations(const Locale('en'));
      expect(directEs.appName, 'Listix');
      expect(directEn.appName, 'Listix');
      expect(directEs.notificationsTitle, isNotEmpty);
      expect(directEn.notificationsTitle, isNotEmpty);
      expect(directEs.weeklyReminderTitle, isNotEmpty);
      expect(directEn.weeklyReminderTitle, isNotEmpty);
      expect(directEs.weeklyReminderSubtitle, isNotEmpty);
      expect(directEn.weeklyReminderSubtitle, isNotEmpty);
      expect(directEs.weeklyReminderNotificationTitle, isNotEmpty);
      expect(directEn.weeklyReminderNotificationTitle, isNotEmpty);
      expect(directEs.weeklyReminderNotificationBody, isNotEmpty);
      expect(directEn.weeklyReminderNotificationBody, isNotEmpty);
      expect(directEs.undo, isNotEmpty);
      expect(directEn.undo, isNotEmpty);
      expect(directEs.listDeleted('Lista'), contains('Lista'));
      expect(directEn.listDeleted('List'), contains('List'));
      expect(directEs.itemDeleted('Item'), contains('Item'));
      expect(directEn.itemDeleted('Item'), contains('Item'));
      expect(directEs.starred, isNotEmpty);
      expect(directEn.starred, isNotEmpty);
      expect(directEs.starList, isNotEmpty);
      expect(directEn.starList, isNotEmpty);
      expect(directEs.unstarList, isNotEmpty);
      expect(directEn.unstarList, isNotEmpty);
      expect(directEs.reorder, isNotEmpty);
      expect(directEn.reorder, isNotEmpty);

      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
    });

    test('AppLocalizationsDelegate methods', () async {
      const delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('es')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
      expect(delegate.shouldReload(delegate), isFalse);

      final loaded = await delegate.load(const Locale('es'));
      expect(loaded.appName, 'Listix');
    });

    testWidgets('AppLocalizations.of retrieves instance in localized context', (
      tester,
    ) async {
      late AppLocalizations retrieved;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              retrieved = AppLocalizations.of(context);
              return Text(retrieved.appName);
            },
          ),
        ),
      );

      expect(retrieved, isNotNull);
      expect(find.text('Listix'), findsOneWidget);
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
          const ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AboutScreen(),
            ),
          ),
        );

        expect(find.text('Listix'), findsOneWidget);
        expect(find.textContaining('1.0.0'), findsOneWidget);

        expect(find.text('Offline-First'), findsOneWidget);
        expect(find.text('Política de Privacidad'), findsOneWidget);
        expect(find.text('Términos del Servicio'), findsOneWidget);

        expect(find.text('Español'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('About Listix'), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen allows navigating to SettingsScreen and shows Listix logo',
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

        expect(find.byType(ListixLogo), findsOneWidget);

        final settingsIconFinder = find.byIcon(Icons.settings_outlined);
        expect(settingsIconFinder, findsOneWidget);
        await tester.tap(settingsIconFinder);
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('Política de Privacidad'), findsOneWidget);
      },
    );
  });
}
