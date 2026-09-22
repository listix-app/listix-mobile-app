import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:listix/src/app.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/features/ads/data/repositories/mock_admob_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
    MockAdmobService.defaultLatency = Duration.zero;
  });

  testWidgets(
    'Listix index test - displays Listix brand name and loads SQLite data',
    (WidgetTester tester) async {
      // Ensure database is initialized before pump
      await tester.runAsync(() async {
        await AppDatabase.instance.database;
      });

      await tester.pumpWidget(const ProviderScope(child: ListixApp()));

      // Drain event loop for Riverpod AsyncNotifier
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Listix brand name on index
      expect(find.text('Listix'), findsOneWidget);

      // Verify section title
      expect(find.text('Mis Listas'), findsOneWidget);

      // Verify initial SQLite seeded lists are rendered
      expect(find.text('Supermercado semanal'), findsOneWidget);
      expect(find.text('Ferretería y Hogar'), findsOneWidget);
      expect(find.text('Ropa para vacaciones'), findsOneWidget);

      // Verify "Nueva lista" FAB is present
      expect(find.text('Nueva lista'), findsOneWidget);

      // Verify AdMob Banner is rendered at bottom
      expect(find.text('Ad'), findsOneWidget);
    },
  );
}
