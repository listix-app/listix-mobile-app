import 'package:flutter/widgets.dart';

import '../entities/admob_ad_state.dart';
import '../entities/mock_admob_campaign.dart';

/// Contract interface defining AdMob services (Banner and Interstitial ads).
abstract class AdmobService {
  /// Initializes the AdMob SDK or mock environment.
  Future<void> initialize();

  /// Whether the service is ready to serve ads.
  bool get isInitialized;

  /// Current state of the banner ad.
  AdmobAdState get bannerState;

  /// Current state of the interstitial ad.
  AdmobAdState get interstitialState;

  /// Stream of banner ad state transitions.
  Stream<AdmobAdState> get bannerStateStream;

  /// Stream of interstitial ad state transitions.
  Stream<AdmobAdState> get interstitialStateStream;

  /// Asynchronously loads or refreshes a banner ad.
  Future<bool> loadBannerAd({String? adUnitId});

  /// Asynchronously preloads an interstitial ad.
  Future<bool> loadInterstitialAd({String? adUnitId});

  /// Returns true if an interstitial ad is loaded and ready to present.
  bool get isInterstitialReady;

  /// Shows the loaded interstitial ad as an interactive full-screen experience.
  /// Returns `true` if shown, `false` if not ready or dismissed.
  Future<bool> showInterstitialAd(
    BuildContext context, {
    VoidCallback? onDismissed,
    VoidCallback? onAdClicked,
  });

  /// Returns the current active creative campaign.
  MockAdmobCampaign getCurrentCampaign({bool next = false});

  /// Records a click / interaction event on the active banner ad.
  void recordBannerClick();

  /// Disposes active stream controllers and timers.
  void dispose();
}
