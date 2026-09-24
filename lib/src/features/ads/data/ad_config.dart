import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

abstract final class AdConfig {
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static String get bannerId {
    if (kIsWeb) return _androidBannerId;
    try {
      if (Platform.isIOS) return _iosBannerId;
    } catch (_) {}
    return _androidBannerId;
  }

  static String get interstitialId {
    if (kIsWeb) return _androidInterstitialId;
    try {
      if (Platform.isIOS) return _iosInterstitialId;
    } catch (_) {}
    return _androidInterstitialId;
  }
}
