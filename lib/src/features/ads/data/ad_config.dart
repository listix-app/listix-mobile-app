import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Centralised AdMob configuration.
///
/// All IDs here are **Google's official test IDs** and are safe to commit.
/// When the app is promoted to production, replace the values in the
/// [_android*] / [_ios*] private constants below with the real Ad Unit IDs
/// obtained from your AdMob account console.
///
/// The App IDs must also be updated in the platform manifests:
///   • Android: android/app/src/main/AndroidManifest.xml  (meta-data key
///              "com.google.android.gms.ads.APPLICATION_ID")
///   • iOS:     ios/Runner/Info.plist  (key "GADApplicationIdentifier")
abstract final class AdConfig {
  /// Google test AdMob App ID for Android.
  /// Replace with your real Android App ID for production.
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Google test AdMob App ID for iOS.
  /// Replace with your real iOS App ID for production.
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Google test Banner Ad Unit ID for Android.
  /// Replace with your real Android Banner Ad Unit ID for production.
  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  /// Google test Banner Ad Unit ID for iOS.
  /// Replace with your real iOS Banner Ad Unit ID for production.
  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// Returns the correct Banner Ad Unit ID for the current platform.
  static String get bannerId {
    if (kIsWeb) return _androidBannerId;
    try {
      if (Platform.isIOS) return _iosBannerId;
    } catch (_) {}
    return _androidBannerId;
  }
}
