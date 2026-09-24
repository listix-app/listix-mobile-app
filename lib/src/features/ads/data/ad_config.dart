abstract final class AdConfig {
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  static String get bannerId => _androidBannerId;

  static String get interstitialId => _androidInterstitialId;
}
