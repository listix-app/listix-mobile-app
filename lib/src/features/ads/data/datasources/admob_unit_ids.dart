import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Official Google AdMob sample test ad unit IDs.
///
/// See AdMob documentation:
/// https://developers.google.com/admob/android/test-ads
/// https://developers.google.com/admob/ios/test-ads
class AdmobUnitIds {
  AdmobUnitIds._();

  // Android Test Ad Units
  static const String androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewarded =
      'ca-app-pub-3940256099942544/5224354917';

  // iOS Test Ad Units
  static const String iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  /// Returns the appropriate test Banner ad unit ID for the current platform.
  static String get bannerTestUnitId {
    if (kIsWeb) return androidBanner;
    try {
      if (Platform.isIOS) return iosBanner;
    } catch (_) {
      // Fallback for non-standard environments
    }
    return androidBanner;
  }

  /// Returns the appropriate test Interstitial ad unit ID for the current platform.
  static String get interstitialTestUnitId {
    if (kIsWeb) return androidInterstitial;
    try {
      if (Platform.isIOS) return iosInterstitial;
    } catch (_) {
      // Fallback for non-standard environments
    }
    return androidInterstitial;
  }
}
