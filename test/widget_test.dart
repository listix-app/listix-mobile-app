import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:listix/src/app.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:listix/src/core/widgets/listix_logo.dart';

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

  testWidgets(
    'Listix index test - displays Listix brand name and loads SQLite data',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        await AppDatabase.instance.database;
      });

      await tester.pumpWidget(const ProviderScope(child: ListixApp()));

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ListixLogo), findsOneWidget);
      expect(find.text('Listix', findRichText: true), findsOneWidget);
      expect(find.text('Mis Listas'), findsOneWidget);
      expect(find.text('Supermercado semanal'), findsOneWidget);
      expect(find.text('Ferretería y Hogar'), findsOneWidget);
      expect(find.text('Ropa para vacaciones'), findsOneWidget);
      expect(find.text('Nueva lista'), findsOneWidget);
    },
  );

  testWidgets(
    'Real-time addition test - item appears immediately upon submitting QuickAddInput',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        await AppDatabase.instance.database;
      });

      await tester.pumpWidget(const ProviderScope(child: ListixApp()));

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Tap on first list to open ListDetailScreen
      await tester.tap(find.text('Supermercado semanal'));
      await tester.pumpAndSettle();

      // Verify ListDetailScreen is open
      expect(find.text('Supermercado semanal'), findsWidgets);

      // Find the QuickAddInput TextField
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Enter a new item name and submit
      await tester.enterText(textFieldFinder, 'Queso parmesano fresco');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Pump single frame to verify instant optimistic render (0ms delay)
      await tester.pump();

      // The item MUST be immediately visible on screen!
      expect(find.text('Queso parmesano fresco'), findsOneWidget);
    },
  );
}
