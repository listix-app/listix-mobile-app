import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:listix/src/core/storage/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'about_and_localization_test.dart' as about_test;
import 'banner_ad_widget_test.dart' as banner_ad_test;
import 'domain_entities_test.dart' as domain_test;
import 'full_coverage_gap_test.dart' as gap_test;
import 'interstitial_and_layout_test.dart' as interstitial_and_layout_test;
import 'lists_controller_test.dart' as lists_controller_test;
import 'mock_sync_service_and_controller_test.dart' as sync_test;
import 'notifications_feature_test.dart' as notif_test;
import 'screens_and_navigation_test.dart' as screens_test;
import 'settings_and_theme_test.dart' as settings_test;
import 'share_service_test.dart' as share_test;
import 'sqlite_lists_repository_test.dart' as repo_test;
import 'theme_and_routes_test.dart' as theme_test;
import 'widget_test.dart' as widget_test;
import 'widgets_presentation_test.dart' as widgets_test;

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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (
          MethodCall call,
        ) async {
          if (call.method == 'loadBannerAd' ||
              call.method == 'loadInterstitialAd') {
            banner_ad_test.lastAdId = call.arguments['adId'] as int;
            return null;
          }
          if (call.method == 'disposeAd' ||
              call.method == 'showAdWithoutView') {
            return null;
          }
          return null;
        });
  });

  about_test.main();
  banner_ad_test.main();
  domain_test.main();
  lists_controller_test.main();
  sync_test.main();
  screens_test.main();
  theme_test.main();
  widget_test.main();
  widgets_test.main();
  gap_test.main();
  repo_test.main();
  settings_test.main();
  share_test.main();
  notif_test.main();
  interstitial_and_layout_test.main();
}
