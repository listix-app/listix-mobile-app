import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/localization/generated/app_localizations.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/core/widgets/listix_logo.dart';
import 'package:listix/src/features/security/data/services/app_lock_service.dart';
import 'package:listix/src/features/security/presentation/controllers/app_lock_controller.dart';
import 'package:listix/src/features/security/presentation/screens/app_lock_screen.dart';
import 'package:listix/src/features/security/presentation/widgets/app_lock_wrapper.dart';
import 'package:listix/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockLocalAuthentication implements LocalAuthentication {
  bool isSupportedResult = true;
  bool canCheckResult = true;
  bool authenticateResult = true;
  bool shouldThrow = false;
  int authenticateCallCount = 0;
  String? lastLocalizedReason;

  @override
  Future<bool> isDeviceSupported() async => isSupportedResult;

  @override
  Future<bool> get canCheckBiometrics async => canCheckResult;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      authenticateCallCount++;
      lastLocalizedReason =
          invocation.namedArguments[#localizedReason] as String?;
      if (shouldThrow) {
        throw Exception('Auth error');
      }
      return Future.value(authenticateResult);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeAppLockService implements AppLockService {
  bool supported = true;
  bool canCheck = true;
  bool authSuccess = true;
  int authCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    authCalls++;
    return authSuccess;
  }
}

class _TestAppLockController extends AppLockController {
  bool toggleResult = true;

  @override
  AppLockState build() => const AppLockState();

  @override
  Future<bool> toggleAppLock({
    required bool enabled,
    required String localizedReason,
  }) async {
    if (toggleResult) {
      state = state.copyWith(isEnabled: enabled);
      return true;
    }
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
    db = AppDatabase.instance;
    await db.database;
  });

  tearDown(() async {
    await db.setSetting(AppLockController.settingKey, '0');
  });

  tearDownAll(() async {
    await db.setSetting(AppLockController.settingKey, '0');
  });

  group('LocalAuthAppLockService Tests', () {
    late MockLocalAuthentication mockAuth;
    late LocalAuthAppLockService service;

    setUp(() {
      mockAuth = MockLocalAuthentication();
      service = LocalAuthAppLockService(auth: mockAuth);
    });

    test('isDeviceSupported delegates to auth', () async {
      expect(await service.isDeviceSupported(), isTrue);
      mockAuth.isSupportedResult = false;
      expect(await service.isDeviceSupported(), isFalse);
    });

    test('canCheckBiometrics delegates to auth', () async {
      expect(await service.canCheckBiometrics(), isTrue);
      mockAuth.canCheckResult = false;
      expect(await service.canCheckBiometrics(), isFalse);
    });

    test('authenticate returns true when auth succeeds', () async {
      final res = await service.authenticate(localizedReason: 'Test reason');
      expect(res, isTrue);
      expect(mockAuth.authenticateCallCount, 1);
      expect(mockAuth.lastLocalizedReason, 'Test reason');
    });

    test('authenticate returns false when auth fails', () async {
      mockAuth.authenticateResult = false;
      final res = await service.authenticate(localizedReason: 'Test reason');
      expect(res, isFalse);
    });

    test('authenticate returns false when auth throws', () async {
      mockAuth.shouldThrow = true;
      final res = await service.authenticate(localizedReason: 'Test reason');
      expect(res, isFalse);
    });

    test('default constructor creates service instance and provider works', () {
      final defaultService = LocalAuthAppLockService();
      expect(defaultService, isNotNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provided = container.read(appLockServiceProvider);
      expect(provided, isA<LocalAuthAppLockService>());
    });
  });

  group('AppLockState Tests', () {
    test('default constructor and copyWith', () {
      const state = AppLockState();
      expect(state.isEnabled, isFalse);
      expect(state.isLocked, isFalse);
      expect(state.isAuthenticating, isFalse);

      final modified = state.copyWith(
        isEnabled: true,
        isLocked: true,
        isAuthenticating: true,
      );
      expect(modified.isEnabled, isTrue);
      expect(modified.isLocked, isTrue);
      expect(modified.isAuthenticating, isTrue);

      final partial = modified.copyWith(isLocked: false);
      expect(partial.isEnabled, isTrue);
      expect(partial.isLocked, isFalse);
      expect(partial.isAuthenticating, isTrue);
    });

    test('operator == and hashCode', () {
      const s1 = AppLockState(
        isEnabled: true,
        isLocked: false,
        isAuthenticating: false,
      );
      const s2 = AppLockState(
        isEnabled: true,
        isLocked: false,
        isAuthenticating: false,
      );
      const s3 = AppLockState(
        isEnabled: false,
        isLocked: false,
        isAuthenticating: false,
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1 == s3, isFalse);
    });
  });

  group('AppLockController Tests', () {
    test('build reads disabled state from database by default', () async {
      await db.setSetting(AppLockController.settingKey, '0');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appLockControllerProvider);
      expect(state.isEnabled, isFalse);
      expect(state.isLocked, isFalse);
    });

    test('build reads enabled state from database when set to 1', () async {
      await db.setSetting(AppLockController.settingKey, '1');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(appLockControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(appLockControllerProvider);
      expect(state.isEnabled, isTrue);
      expect(state.isLocked, isTrue);
    });

    test(
      'unlock returns true immediately when not enabled or not locked',
      () async {
        final fake = FakeAppLockService();
        final container = ProviderContainer(
          overrides: [appLockServiceProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(appLockControllerProvider.notifier);
        expect(await ctrl.unlock('reason'), isTrue);
        expect(fake.authCalls, 0);
      },
    );

    test('unlock succeeds when authenticating successfully', () async {
      await db.setSetting(AppLockController.settingKey, '1');
      final fake = FakeAppLockService()..authSuccess = true;
      final container = ProviderContainer(
        overrides: [appLockServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(appLockControllerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(appLockControllerProvider).isLocked, isTrue);

      final success = await ctrl.unlock('reason');
      expect(success, isTrue);
      expect(fake.authCalls, 1);
      expect(container.read(appLockControllerProvider).isLocked, isFalse);
      expect(
        container.read(appLockControllerProvider).isAuthenticating,
        isFalse,
      );
    });

    test('unlock fails when authentication returns false', () async {
      await db.setSetting(AppLockController.settingKey, '1');
      final fake = FakeAppLockService()..authSuccess = false;
      final container = ProviderContainer(
        overrides: [appLockServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(appLockControllerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(appLockControllerProvider).isLocked, isTrue);

      final success = await ctrl.unlock('reason');
      expect(success, isFalse);
      expect(fake.authCalls, 1);
      expect(container.read(appLockControllerProvider).isLocked, isTrue);
      expect(
        container.read(appLockControllerProvider).isAuthenticating,
        isFalse,
      );
    });

    test('toggleAppLock updates database on authentication success', () async {
      final fake = FakeAppLockService()..authSuccess = true;
      final container = ProviderContainer(
        overrides: [appLockServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(appLockControllerProvider.notifier);
      final ok = await ctrl.toggleAppLock(
        enabled: true,
        localizedReason: 'test',
      );
      expect(ok, isTrue);
      expect(container.read(appLockControllerProvider).isEnabled, isTrue);
      expect(await db.getSetting(AppLockController.settingKey), '1');

      final disableOk = await ctrl.toggleAppLock(
        enabled: false,
        localizedReason: 'test',
      );
      expect(disableOk, isTrue);
      expect(container.read(appLockControllerProvider).isEnabled, isFalse);
      expect(await db.getSetting(AppLockController.settingKey), '0');
    });

    test(
      'toggleAppLock returns false on auth failure without updating db',
      () async {
        await db.setSetting(AppLockController.settingKey, '0');
        final fake = FakeAppLockService()..authSuccess = false;
        final container = ProviderContainer(
          overrides: [appLockServiceProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(appLockControllerProvider.notifier);
        final ok = await ctrl.toggleAppLock(
          enabled: true,
          localizedReason: 'test',
        );
        expect(ok, isFalse);
        expect(container.read(appLockControllerProvider).isEnabled, isFalse);
        expect(await db.getSetting(AppLockController.settingKey), '0');
      },
    );

    test(
      'lock sets isLocked when isEnabled is true and not currently locked',
      () async {
        final fake = FakeAppLockService();
        final container = ProviderContainer(
          overrides: [appLockServiceProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(appLockControllerProvider.notifier);
        await ctrl.toggleAppLock(enabled: true, localizedReason: 'test');
        expect(container.read(appLockControllerProvider).isLocked, isFalse);

        ctrl.lock();
        expect(container.read(appLockControllerProvider).isLocked, isTrue);

        ctrl.lock();
        expect(container.read(appLockControllerProvider).isLocked, isTrue);
      },
    );
  });

  group('AppLockScreen & AppLockWrapper Widget Tests', () {
    testWidgets(
      'AppLockScreen renders logo, locked message, and triggers unlock',
      (tester) async {
        final fake = FakeAppLockService()..authSuccess = false;
        final container = ProviderContainer(
          overrides: [appLockServiceProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(appLockControllerProvider.notifier);
        ctrl.state = ctrl.state.copyWith(isEnabled: true, isLocked: true);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AppLockScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ListixLogo), findsOneWidget);
        expect(find.text('Listix está bloqueado'), findsOneWidget);

        final button = find.byKey(const Key('unlock_app_button'));
        expect(button, findsOneWidget);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(fake.authCalls, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'AppLockScreen displays loading indicator when authenticating',
      (tester) async {
        final fake = FakeAppLockService();
        final container = ProviderContainer(
          overrides: [appLockServiceProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              themeMode: ThemeMode.dark,
              home: AppLockScreen(),
            ),
          ),
        );

        final ctrl = container.read(appLockControllerProvider.notifier);
        ctrl.state = ctrl.state.copyWith(
          isEnabled: true,
          isLocked: true,
          isAuthenticating: true,
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('AppLockWrapper renders child and shows overlay when locked', (
      tester,
    ) async {
      final fake = FakeAppLockService()..authSuccess = false;
      final container = ProviderContainer(
        overrides: [appLockServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppLockWrapper(child: Scaffold(body: Text('Secret content'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret content'), findsOneWidget);
      expect(find.byType(AppLockScreen), findsNothing);

      final ctrl = container.read(appLockControllerProvider.notifier);
      ctrl.state = ctrl.state.copyWith(isEnabled: true, isLocked: true);
      await tester.pumpAndSettle();

      expect(find.byType(AppLockScreen), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    });

    testWidgets('SettingsScreen Security AppLock toggle succeeds and fails', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testCtrl = _TestAppLockController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appLockControllerProvider.overrideWith(() => testCtrl)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchTile = find.byKey(const Key('app_lock_switch'));
      await tester.scrollUntilVisible(switchTile, 200);
      await tester.pumpAndSettle();

      final switchWidget = find.descendant(
        of: switchTile,
        matching: find.byType(Switch),
      );
      expect(switchWidget, findsOneWidget);

      testCtrl.toggleResult = true;
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();
      expect(testCtrl.state.isEnabled, isTrue);

      testCtrl.toggleResult = false;
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('Falló la autenticación'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
    });
  });
}
