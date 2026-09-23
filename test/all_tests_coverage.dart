import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:listix/src/core/storage/app_database.dart';

import 'about_and_localization_test.dart' as about_test;
import 'domain_entities_test.dart' as domain_test;
import 'lists_controller_test.dart' as lists_controller_test;
import 'mock_admob_service_test.dart' as admob_test;
import 'mock_sync_service_and_controller_test.dart' as sync_test;
import 'screens_and_navigation_test.dart' as screens_test;
import 'theme_and_routes_test.dart' as theme_test;
import 'widget_test.dart' as widget_test;
import 'widgets_presentation_test.dart' as widgets_test;
import 'full_coverage_gap_test.dart' as gap_test;
import 'sqlite_lists_repository_test.dart' as repo_test;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.overrideDbPath = inMemoryDatabasePath;
  });

  about_test.main();
  domain_test.main();
  lists_controller_test.main();
  admob_test.main();
  sync_test.main();
  screens_test.main();
  theme_test.main();
  widget_test.main();
  widgets_test.main();
  gap_test.main();
  repo_test.main();
}
