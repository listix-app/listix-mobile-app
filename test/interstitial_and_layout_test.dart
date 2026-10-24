import 'package:listix/src/features/sync/domain/pending_operation.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/features/lists/domain/entities/collaborator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:listix/src/core/localization/app_strings.dart';
import 'package:listix/src/core/theme/app_colors.dart';
import 'package:listix/src/core/config/app_environment.dart';
import 'package:listix/src/core/services/url_launcher_service.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/about/presentation/screens/about_screen.dart';
import 'package:listix/src/features/ads/data/ad_config.dart';
import 'package:listix/src/features/ads/data/interstitial_ad_service.dart';
import 'package:listix/src/features/lists/domain/entities/shopping_list.dart';
import 'package:listix/src/features/lists/domain/entities/todo_item.dart';
import 'package:listix/src/features/lists/domain/repositories/lists_repository.dart';
import 'package:listix/src/features/lists/presentation/controllers/list_layout_controller.dart';
import 'package:listix/src/features/lists/presentation/controllers/lists_controller.dart';
import 'package:listix/src/features/lists/presentation/screens/home_screen.dart';
import 'package:listix/src/features/lists/presentation/widgets/list_grid_card.dart';
import 'package:listix/src/features/notifications/data/services/notification_service.dart';
import 'package:listix/src/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:listix/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher/url_launcher.dart';

import 'banner_ad_widget_test.dart' as banner_ad_test;

int lastLoadedAdId = -1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
  });

  setUp(() async {
    db = AppDatabase.instance;
    await db.database;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (
          MethodCall call,
        ) async {
          if (call.method == 'loadBannerAd' ||
              call.method == 'loadInterstitialAd') {
            lastLoadedAdId = call.arguments['adId'] as int;
            banner_ad_test.lastAdId = lastLoadedAdId;
            return null;
          }
          if (call.method == 'disposeAd' ||
              call.method == 'showAdWithoutView') {
            return null;
          }
          return null;
        });
  });

  group('AdConfig interstitialId Tests', () {
    test('AdConfig provides valid interstitialId', () {
      expect(AdConfig.interstitialId, isNotEmpty);
    });
  });

  group('AppEnvironmentConfig Tests', () {
    test('parses every environment name and unknown fallbacks', () {
      expect(AppEnvironmentConfig.parse('dev'), AppEnvironment.dev);
      expect(AppEnvironmentConfig.parse(' preview '), AppEnvironment.preview);
      expect(AppEnvironmentConfig.parse('STAGING'), AppEnvironment.preview);
      expect(AppEnvironmentConfig.parse('prod'), AppEnvironment.prod);
      expect(AppEnvironmentConfig.parse('Production'), AppEnvironment.prod);
      expect(AppEnvironmentConfig.parse('unknown'), AppEnvironment.dev);
    });

    test('ads are only enabled outside production', () {
      expect(AppEnvironmentConfig.rawName, isNotEmpty);
      expect(AppEnvironmentConfig.current, AppEnvironment.dev);
      expect(AppEnvironmentConfig.adsEnabled, isTrue);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(adsEnabledProvider), isTrue);
    });

    test('interstitialAdServiceProvider mirrors the ads enabled flag', () {
      final enabledContainer = ProviderContainer(
        overrides: [adsEnabledProvider.overrideWithValue(true)],
      );
      addTearDown(enabledContainer.dispose);
      expect(
        enabledContainer.read(interstitialAdServiceProvider),
        isA<InterstitialAdService>(),
      );

      final disabledContainer = ProviderContainer(
        overrides: [adsEnabledProvider.overrideWithValue(false)],
      );
      addTearDown(disabledContainer.dispose);
      expect(
        disabledContainer.read(interstitialAdServiceProvider),
        isA<InterstitialAdService>(),
      );
    });
  });

  group('ShoppingList completionProgress Tests', () {
    test(
      'completionProgress returns 0 when empty and fraction when items exist',
      () {
        final now = DateTime(2026, 9, 23);
        final emptyList = ShoppingList(id: '1', name: 'Empty', createdAt: now);
        expect(emptyList.completionProgress, 0.0);

        final populated = ShoppingList(
          id: '2',
          name: 'Populated',
          items: [
            TodoItem(
              id: 'i1',
              listId: '2',
              title: 'A',
              isCompleted: true,
              createdAt: now,
            ),
            TodoItem(
              id: 'i2',
              listId: '2',
              title: 'B',
              isCompleted: false,
              createdAt: now,
            ),
          ],
          createdAt: now,
        );
        expect(populated.completionProgress, 0.5);
      },
    );
  });

  group('UrlLauncherService Tests', () {
    test('openUrl succeeds with valid url and custom launcher', () async {
      var launched = false;
      final service = UrlLauncherService(
        customLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
          launched = true;
          return true;
        },
      );
      final res = await service.openUrl('https://buymeacoffee.com/nmenag');
      expect(res, isTrue);
      expect(launched, isTrue);
    });

    test(
      'openUrl and openEmail with default launcher and channel simulation',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/url_launcher'),
              (MethodCall call) async => true,
            );

        const defaultService = UrlLauncherService();
        final openedUrl = await defaultService.openUrl(
          'https://buymeacoffee.com/nmenag',
        );
        expect(openedUrl, isTrue);

        final openedEmail = await defaultService.openEmail(
          'nmena.garzon@gmail.com',
        );
        expect(openedEmail, isTrue);
      },
    );

    test('openUrl returns false on invalid uri or throwing launcher', () async {
      final throwingService = UrlLauncherService(
        customLauncher: (uri, {mode = LaunchMode.platformDefault}) async =>
            throw Exception('error'),
      );
      final res = await throwingService.openUrl('https://example.com');
      expect(res, isFalse);

      const defaultService = UrlLauncherService();
      final resDefault = await defaultService.openUrl(':::invalid-uri:::');
      expect(resDefault, isFalse);
    });

    test(
      'openEmail launches mailto with subject and without subject',
      () async {
        Uri? capturedUri;
        final service = UrlLauncherService(
          customLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
            capturedUri = uri;
            return true;
          },
        );

        final res1 = await service.openEmail(
          'test@example.com',
          subject: 'Hello',
        );
        expect(res1, isTrue);
        expect(capturedUri?.scheme, 'mailto');
        expect(capturedUri?.path, 'test@example.com');
        expect(capturedUri?.queryParameters['subject'], 'Hello');

        final res2 = await service.openEmail('test2@example.com');
        expect(res2, isTrue);
        expect(capturedUri?.path, 'test2@example.com');
        expect(capturedUri?.queryParameters['subject'], isNull);

        final throwingService = UrlLauncherService(
          customLauncher: (uri, {mode = LaunchMode.platformDefault}) async =>
              throw Exception('error'),
        );
        final resThrow = await throwingService.openEmail('test@example.com');
        expect(resThrow, isFalse);
      },
    );

    test('urlLauncherServiceProvider provides instance', () {
      final container = ProviderContainer();
      final service = container.read(urlLauncherServiceProvider);
      expect(service, isA<UrlLauncherService>());
    });
  });

  group('AppDatabase Settings Tests', () {
    test('getSetting and setSetting store and retrieve values', () async {
      await db.setSetting('test_key', 'test_value');
      final val = await db.getSetting('test_key');
      expect(val, 'test_value');

      final missing = await db.getSetting('non_existing_key');
      expect(missing, isNull);
    });
  });

  group('InterstitialAdService Tests', () {
    test(
      'canShowToday logic for null, invalid, same day, and next day',
      () async {
        await db.setSetting(InterstitialAdService.lastShownKey, '');
        final serviceInvalid = InterstitialAdService(db: db);
        expect(await serviceInvalid.canShowToday(), isTrue);

        final now = DateTime(2026, 9, 23, 10, 0);
        final serviceClock = InterstitialAdService(db: db, clock: () => now);

        await serviceClock.recordAdShown(now);
        expect(await serviceClock.canShowToday(), isFalse);

        final nextDay = DateTime(2026, 9, 24, 10, 0);
        final serviceNextDay = InterstitialAdService(
          db: db,
          clock: () => nextDay,
        );
        expect(await serviceNextDay.canShowToday(), isTrue);
      },
    );

    test(
      'showInterstitialIfAllowed never shows ads when ads are disabled',
      () async {
        var adLauncherCalled = false;
        final service = InterstitialAdService(
          db: db,
          clock: () => DateTime(2026, 5, 1),
          adsEnabled: false,
          adLauncher: (id) async {
            adLauncherCalled = true;
            return true;
          },
        );

        await db.setSetting(
          InterstitialAdService.lastShownKey,
          DateTime(2026, 4, 30).toIso8601String(),
        );

        expect(await service.showInterstitialIfAllowed(), isFalse);
        expect(adLauncherCalled, isFalse);
        expect(
          await db.getSetting(InterstitialAdService.lastShownKey),
          DateTime(2026, 4, 30).toIso8601String(),
        );
      },
    );

    test('showInterstitialIfAllowed with custom launcher', () async {
      final now = DateTime(2026, 5, 1, 10, 0);
      var adShown = false;
      final service = InterstitialAdService(
        db: db,
        clock: () => now,
        adLauncher: (id) async {
          adShown = true;
          return true;
        },
      );

      await db.setSetting(
        InterstitialAdService.lastShownKey,
        DateTime(2026, 4, 30).toIso8601String(),
      );
      final showed = await service.showInterstitialIfAllowed();
      expect(showed, isTrue);
      expect(adShown, isTrue);

      final showedSecondTime = await service.showInterstitialIfAllowed();
      expect(showedSecondTime, isFalse);

      final failingService = InterstitialAdService(
        db: db,
        clock: () => DateTime(2026, 5, 2),
        adLauncher: (id) async => false,
      );
      final failed = await failingService.showInterstitialIfAllowed();
      expect(failed, isFalse);
    });

    test(
      'showInterstitialIfAllowed with default launcher load and show',
      () async {
        final service = InterstitialAdService(
          db: db,
          clock: () => DateTime(2026, 6, 1),
        );
        await db.setSetting(
          InterstitialAdService.lastShownKey,
          DateTime(2026, 5, 31).toIso8601String(),
        );

        final future = service.showInterstitialIfAllowed();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final adId = lastLoadedAdId;
        expect(adId, isNonNegative);

        final ByteData message = instanceManager.channel.codec.encodeMethodCall(
          MethodCall('onAdEvent', {'adId': adId, 'eventName': 'onAdLoaded'}),
        );
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              instanceManager.channel.name,
              message,
              (data) {},
            );

        final ByteData dismissMsg = instanceManager.channel.codec
            .encodeMethodCall(
              MethodCall('onAdEvent', {
                'adId': adId,
                'eventName': 'onAdDismissedFullScreenContent',
              }),
            );
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              instanceManager.channel.name,
              dismissMsg,
              (data) {},
            );

        final res = await future;
        expect(res, isTrue);
      },
    );

    test(
      'showInterstitialIfAllowed handles onAdFailedToShowFullScreenContent',
      () async {
        final service = InterstitialAdService(
          db: db,
          clock: () => DateTime(2026, 8, 1),
        );
        await db.setSetting(
          InterstitialAdService.lastShownKey,
          DateTime(2026, 7, 31).toIso8601String(),
        );

        final future = service.showInterstitialIfAllowed();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final adId = lastLoadedAdId;
        expect(adId, isNonNegative);

        final ByteData loadedMsg = instanceManager.channel.codec
            .encodeMethodCall(
              MethodCall('onAdEvent', {
                'adId': adId,
                'eventName': 'onAdLoaded',
              }),
            );
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              instanceManager.channel.name,
              loadedMsg,
              (data) {},
            );

        final ByteData failedShowMsg = instanceManager.channel.codec
            .encodeMethodCall(
              MethodCall('onAdEvent', {
                'adId': adId,
                'eventName': 'onFailedToShowFullScreenContent',
                'error': AdError(1, 'domain', 'Show failed'),
              }),
            );
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              instanceManager.channel.name,
              failedShowMsg,
              (data) {},
            );

        final res = await future;
        expect(res, isTrue);
      },
    );

    test('showInterstitialIfAllowed handles show error', () async {
      final service = InterstitialAdService(
        db: db,
        clock: () => DateTime(2026, 8, 2),
      );
      await db.setSetting(
        InterstitialAdService.lastShownKey,
        DateTime(2026, 8, 1).toIso8601String(),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(instanceManager.channel, (
            MethodCall call,
          ) async {
            if (call.method == 'loadInterstitialAd') {
              lastLoadedAdId = call.arguments['adId'] as int;
              return null;
            }
            if (call.method == 'showAdWithoutView') {
              throw PlatformException(code: 'ERROR', message: 'Cannot show ad');
            }
            return null;
          });

      final future = service.showInterstitialIfAllowed();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final adId = lastLoadedAdId;
      final ByteData loadedMsg = instanceManager.channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': adId, 'eventName': 'onAdLoaded'}),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            instanceManager.channel.name,
            loadedMsg,
            (data) {},
          );

      final res = await future;
      expect(res, isFalse);
    });

    test('showInterstitialIfAllowed handles load exception', () async {
      final service = InterstitialAdService(
        db: db,
        clock: () => DateTime(2026, 8, 3),
      );
      await db.setSetting(
        InterstitialAdService.lastShownKey,
        DateTime(2026, 8, 2).toIso8601String(),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(instanceManager.channel, (
            MethodCall call,
          ) async {
            if (call.method == 'loadInterstitialAd') {
              throw PlatformException(code: 'LOAD_ERROR');
            }
            return null;
          });

      final res = await service.showInterstitialIfAllowed();
      expect(res, isFalse);
    });

    test('showInterstitialIfAllowed handles onAdFailedToLoad', () async {
      final service = InterstitialAdService(
        db: db,
        clock: () => DateTime(2026, 7, 1),
      );
      await db.setSetting(
        InterstitialAdService.lastShownKey,
        DateTime(2026, 6, 30).toIso8601String(),
      );

      final future = service.showInterstitialIfAllowed();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final adId = lastLoadedAdId;
      expect(adId, isNonNegative);

      final error = LoadAdError(1, 'domain', 'Failed', null);
      final ByteData message = instanceManager.channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {
          'adId': adId,
          'eventName': 'onAdFailedToLoad',
          'loadAdError': error,
        }),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            instanceManager.channel.name,
            message,
            (data) {},
          );

      final res = await future;
      expect(res, isFalse);
    });

    test('interstitialAdServiceProvider provides instance', () {
      final container = ProviderContainer();
      final service = container.read(interstitialAdServiceProvider);
      expect(service, isA<InterstitialAdService>());
    });
  });

  group('ListLayoutController Tests', () {
    test('build loads saved layout mode and toggles', () async {
      await db.setSetting('list_layout_mode', 'grid');
      final container = ProviderContainer();
      final controller = container.read(listLayoutControllerProvider.notifier);
      expect(container.read(listLayoutControllerProvider), ListLayoutMode.list);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(listLayoutControllerProvider), ListLayoutMode.grid);

      await controller.toggleLayout();
      expect(container.read(listLayoutControllerProvider), ListLayoutMode.list);

      await controller.toggleLayout();
      expect(container.read(listLayoutControllerProvider), ListLayoutMode.grid);

      await controller.setLayoutMode(ListLayoutMode.list);
      expect(container.read(listLayoutControllerProvider), ListLayoutMode.list);
    });
  });

  group('ListGridCard Widget Tests', () {
    testWidgets('renders all states and handles tap, delete, and star toggle', (
      tester,
    ) async {
      var tapped = false;
      var deleted = false;
      var starred = false;

      final emptyList = ShoppingList(
        id: 'g1',
        name: 'Empty Grid List',
        isStarred: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListGridCard(
              list: emptyList,
              onTap: () => tapped = true,
              onDelete: () => deleted = true,
              onToggleStar: () => starred = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty Grid List'), findsOneWidget);
      expect(find.text('Sin items'), findsOneWidget);

      await tester.tap(find.text('Empty Grid List'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.star_outline_rounded));
      expect(starred, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);

      final completedList = ShoppingList(
        id: 'g2',
        name: 'Completed List',
        isStarred: true,
        items: [
          TodoItem(
            id: 'i1',
            listId: 'g2',
            title: 'Milk',
            isCompleted: true,
            createdAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ListGridCard(
              list: completedList,
              strings: AppStrings(AppLanguage.es),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Completed List'), findsOneWidget);
      expect(find.text('Todo listo ✓'), findsOneWidget);
      final gridIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(gridIndicator.valueColor?.value, AppColors.primary);

      final partialList = ShoppingList(
        id: 'g3',
        name: 'Partial List',
        items: [
          TodoItem(
            id: 'i1',
            listId: 'g3',
            title: 'Milk',
            isCompleted: true,
            createdAt: DateTime.now(),
          ),
          TodoItem(
            id: 'i2',
            listId: 'g3',
            title: 'Bread',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListGridCard(
              list: partialList,
              onTap: () {},
              onDelete: () => longPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Partial List'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      await tester.longPress(find.text('Partial List'));
      expect(longPressed, isTrue);
    });

    testWidgets(
      'renders ListGridCard with color, onArchive and onUnarchive callbacks',
      (tester) async {
        var archived = false;
        var unarchived = false;
        final colorList = ShoppingList(
          id: 'g_col',
          name: 'Color Grid List',
          color: 0xFFEF4444,
          items: [
            TodoItem(
              id: 'i1',
              listId: 'g_col',
              title: 'Item 1',
              isCompleted: false,
              createdAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ListGridCard(
                list: colorList,
                onTap: () {},
                onArchive: () => archived = true,
                onUnarchive: () => unarchived = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
        expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);

        await tester.tap(find.byIcon(Icons.archive_outlined));
        expect(archived, isTrue);

        await tester.tap(find.byIcon(Icons.unarchive_outlined));
        expect(unarchived, isTrue);
      },
    );

    testWidgets(
      'renders custom list color on progress indicator when all items completed',
      (tester) async {
        final completedColorList = ShoppingList(
          id: 'g_done_color',
          name: 'Completed Color List',
          color: 0xFFEF4444,
          items: [
            TodoItem(
              id: 'i1',
              listId: 'g_done_color',
              title: 'Milk',
              isCompleted: true,
              createdAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListGridCard(
                list: completedColorList,
                strings: AppStrings(AppLanguage.es),
                onTap: () {},
              ),
            ),
          ),
        );

        final gridIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(gridIndicator.valueColor?.value, const Color(0xFFEF4444));
      },
    );
  });

  group('HomeScreen Grid View and Layout Switcher Tests', () {
    testWidgets(
      'toggles layout to grid and renders GridView with delete/undo flow',
      (tester) async {
        final fakeRepo = _FakeRepoWithLists();
        final container = ProviderContainer(
          overrides: [listsRepositoryProvider.overrideWithValue(fakeRepo)],
        );

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(
              path: '/lists/new',
              builder: (context, state) =>
                  const Scaffold(body: Text('New Screen')),
            ),
            GoRoute(
              path: '/list/:id',
              builder: (context, state) =>
                  const Scaffold(body: Text('Detail Screen')),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('layout_toggle_button')), findsOneWidget);
        expect(find.byType(ReorderableListView), findsOneWidget);

        await tester.tap(find.byKey(const Key('layout_toggle_button')));
        await tester.pumpAndSettle();

        expect(find.byType(SliverGrid), findsOneWidget);
        expect(find.byKey(const ValueKey('grid_card_g1')), findsOneWidget);

        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Grid List 1'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Screen'), findsOneWidget);

        router.go('/');
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('grid_card_g1')),
            matching: find.byIcon(Icons.star_outline_rounded),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('grid_card_g1')),
            matching: find.byIcon(Icons.delete_outline_rounded),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Eliminar'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('grid_card_g1')),
            matching: find.byIcon(Icons.delete_outline_rounded),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();

        expect(find.text('Deshacer'), findsOneWidget);
        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('grid_card_g1')),
            matching: find.byIcon(Icons.archive_outlined),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Archivar'));
        await tester.pumpAndSettle();

        expect(find.text('Lista archivada'), findsOneWidget);
        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('grid_card_g1')),
            matching: find.byIcon(Icons.archive_outlined),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Archivar'));
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('Archivadas'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('grid_card_g1')),
            matching: find.byIcon(Icons.unarchive_outlined),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lista restaurada'), findsOneWidget);
        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();

        fakeRepo.lists.add(
          ShoppingList(
            id: 'g_shared',
            name: 'Shared Grid',
            isOwner: false,
            createdAt: DateTime.now(),
          ),
        );
        await container.read(listsControllerProvider.notifier).manualSync();
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('Activas'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('grid_card_g_shared')),
            matching: find.byIcon(Icons.delete_outline_rounded),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Abandonar lista?'), findsOneWidget);
        expect(
          find.text('Abandonarás "Shared Grid" y perderás el acceso.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Abandonar'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('layout_toggle_button')));
        await tester.pump(const Duration(seconds: 15));
        await tester.pumpAndSettle();
      },
    );
  });

  group('AboutScreen & SettingsScreen Action Cards Tests', () {
    testWidgets('AboutScreen action cards open URLs and email', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var openedCoffee = false;
      var openedFeedback = false;
      var openedStore = false;

      final testLauncher = UrlLauncherService(
        customLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
          if (uri.toString().contains('buymeacoffee')) openedCoffee = true;
          if (uri.toString().contains('play.google')) openedStore = true;
          if (uri.scheme == 'mailto') openedFeedback = true;
          return true;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            urlLauncherServiceProvider.overrideWithValue(testLauncher),
          ],
          child: const MaterialApp(home: AboutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('buy_coffee_card')));
      expect(openedCoffee, isTrue);

      await tester.tap(find.byKey(const Key('rate_app_card')));
      expect(openedStore, isTrue);

      await tester.tap(find.byKey(const Key('send_feedback_card')));
      expect(openedFeedback, isTrue);
    });

    testWidgets(
      'SettingsScreen action cards and layout switcher function correctly',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        var openedCoffee = false;
        var openedFeedback = false;
        var openedStore = false;

        final testLauncher = UrlLauncherService(
          customLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
            if (uri.toString().contains('buymeacoffee')) openedCoffee = true;
            if (uri.toString().contains('play.google')) openedStore = true;
            if (uri.scheme == 'mailto') openedFeedback = true;
            return true;
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              urlLauncherServiceProvider.overrideWithValue(testLauncher),
              notificationServiceProvider.overrideWithValue(
                _TestSettingsNotificationService(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SettingsScreen(showBuyCoffee: true, showRateApp: true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('layout_segmented_button')),
          findsOneWidget,
        );
        await tester.tap(find.text('Bloques'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_buy_coffee')));
        expect(openedCoffee, isTrue);

        await tester.tap(find.byKey(const Key('settings_send_feedback')));
        expect(openedFeedback, isTrue);

        await tester.tap(find.byKey(const Key('settings_rate_app')));
        expect(openedStore, isTrue);

        await tester.ensureVisible(
          find.byKey(const Key('notification_switch')),
        );
        await tester.pumpAndSettle();
        final switchFinder = find.byType(Switch);
        await tester.tap(switchFinder.first);
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 15));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'SettingsScreen hides coffee and rate app by default under supportAndFeedback group',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notificationServiceProvider.overrideWithValue(
                _TestSettingsNotificationService(),
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

        expect(find.text('SOPORTE Y COMENTARIOS'), findsOneWidget);
        expect(find.byKey(const Key('settings_buy_coffee')), findsNothing);
        expect(find.byKey(const Key('settings_rate_app')), findsNothing);
        expect(find.byKey(const Key('settings_send_feedback')), findsOneWidget);

        await tester.pump(const Duration(seconds: 15));
        await tester.pumpAndSettle();
      },
    );
  });
}

class _FakeRepoWithLists implements ListsRepository {
  List<ShoppingList> lists = [
    ShoppingList(
      id: 'g1',
      name: 'Grid List 1',
      isStarred: false,
      items: const [],
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<ShoppingList>> getLists() async => lists;

  @override
  Future<ShoppingList?> getListById(String id) async =>
      lists.where((l) => l.id == id).firstOrNull;

  @override
  Future<ShoppingList> createList(String name, {int? color}) async {
    final l = ShoppingList(
      id: 'new',
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );
    lists.add(l);
    return l;
  }

  @override
  Future<ShoppingList> updateListName(
    String id,
    String newName, {
    int? color,
  }) async {
    final idx = lists.indexWhere((l) => l.id == id);
    final updated = lists[idx].copyWith(name: newName, color: color);
    lists[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteList(String id) async {
    lists.removeWhere((l) => l.id == id);
  }

  @override
  Future<List<ShoppingList>> deleteArchivedLists() async => const [];

  @override
  Future<void> restoreList(ShoppingList list) async {
    lists.add(list);
  }

  @override
  Future<void> toggleListStar(String listId) async {
    final idx = lists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      lists[idx] = lists[idx].copyWith(isStarred: !lists[idx].isStarred);
    }
  }

  @override
  Future<void> reorderLists(List<String> orderedListIds) async {}

  @override
  Future<TodoItem> addItem(String listId, String title, {String? id}) async {
    return TodoItem(
      id: id ?? 'item',
      listId: listId,
      title: title,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<TodoItem> toggleItemCompletion(String listId, String itemId) async {
    return TodoItem(
      id: itemId,
      listId: listId,
      title: 'Item',
      isCompleted: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {}

  @override
  Future<List<TodoItem>> deleteCompletedItems(String listId) async => const [];

  @override
  Future<void> restoreItem(TodoItem item) async {}

  @override
  Future<void> restoreItems(List<TodoItem> items) async {}

  @override
  Future<void> reorderItems(String listId, List<String> orderedItemIds) async {}

  @override
  Future<void> addCollaborator(
    String listId,
    String email, {
    CollaboratorRole role = CollaboratorRole.member,
  }) async {}

  @override
  Future<void> updateCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {}

  @override
  Future<void> applyRemoteCollaboratorRole(
    String listId,
    String collaboratorId,
    CollaboratorRole role,
  ) async {}

  @override
  Future<void> removeCollaborator(String listId, String collaboratorId) async {}

  @override
  Future<void> syncList(String listId) async {}

  @override
  Future<void> setListShared(
    String listId,
    bool isShared, {
    bool? hasInvite,
  }) async {
    final idx = lists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      lists[idx] = lists[idx].copyWith(
        isShared: isShared,
        hasInvite: isShared ? (hasInvite ?? lists[idx].hasInvite) : false,
      );
    }
  }

  @override
  Future<void> markListInviteCreated(String listId) async {
    final idx = lists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      lists[idx] = lists[idx].copyWith(isShared: true, hasInvite: true);
    }
  }

  @override
  Future<ShoppingList> joinSharedList(
    String listId,
    String name, {
    String? ownerName,
    String? ownerEmail,
  }) async {
    final l = ShoppingList(
      id: listId,
      name: name,
      createdAt: DateTime.now(),
      collaborators: [
        Collaborator(
          id: 'collab_owner',
          name: ownerName ?? 'Owner',
          email: ownerEmail ?? 'owner@listix.local',
          isOwner: true,
        ),
      ],
    );
    lists.add(l);
    return l;
  }

  @override
  Future<void> applyRemoteItem(TodoItem item) async {}

  @override
  Future<void> applyRemoteItemToggle(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {}

  @override
  Future<void> applyRemoteItemDelete(String listId, String itemId) async {}

  @override
  Future<void> applyRemoteCollaborator(
    String listId,
    Collaborator collaborator,
  ) async {}

  @override
  Future<void> applyRemoteCollaboratorRemove(
    String listId,
    String collaboratorId,
  ) async {}

  @override
  Future<void> saveRemoteList(ShoppingList list) async {
    final idx = lists.indexWhere((l) => l.id == list.id);
    if (idx != -1) {
      lists[idx] = list;
    } else {
      lists.add(list);
    }
  }

  @override
  Future<List<PendingOperation>> getPendingOperations({String? listId}) async =>
      [];

  @override
  Future<void> removePendingOperation(String id) async {}

  @override
  Future<void> clearPendingOperationsForList(String listId) async {}

  @override
  Future<void> archiveList(String listId) async {
    final idx = lists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      lists[idx] = lists[idx].copyWith(isArchived: true);
    }
  }

  @override
  Future<void> unarchiveList(String listId) async {
    final idx = lists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      lists[idx] = lists[idx].copyWith(isArchived: false);
    }
  }

  @override
  Future<TodoItem> updateItemTitle(
    String listId,
    String itemId,
    String newTitle,
  ) async {
    final idx = lists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      final itemIdx = lists[idx].items.indexWhere((i) => i.id == itemId);
      if (itemIdx != -1) {
        final updated = lists[idx].items[itemIdx].copyWith(title: newTitle);
        final newItems = List<TodoItem>.from(lists[idx].items);
        newItems[itemIdx] = updated;
        lists[idx] = lists[idx].copyWith(items: newItems);
        return updated;
      }
    }
    throw UnimplementedError();
  }

  @override
  Future<void> applyRemoteItemUpdate(
    String listId,
    String itemId,
    String newTitle,
  ) async {
    await updateItemTitle(listId, itemId, newTitle);
  }
}

class _TestSettingsNotificationService implements NotificationService {
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

  @override
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {}
}
