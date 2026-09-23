import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/ad_config.dart';

/// Lifecycle states for a banner ad.
enum BannerAdStatus { loading, loaded, failed }

/// Riverpod notifier that owns and manages a single [BannerAd] lifecycle.
///
/// The ad is requested on first use and disposed automatically when the
/// provider is no longer needed (Riverpod calls [ref.onDispose]).
class BannerAdNotifier extends Notifier<BannerAdStatus> {
  BannerAd? _ad;

  /// The loaded [BannerAd] instance — null until the ad has loaded.
  BannerAd? get ad => _ad;

  @override
  BannerAdStatus build() {
    _load();
    ref.onDispose(_disposeAd);
    return BannerAdStatus.loading;
  }

  void _load() {
    _disposeAd();
    state = BannerAdStatus.loading;

    _ad = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          state = BannerAdStatus.loaded;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[BannerAd] Failed to load: ${error.message}');
          ad.dispose().catchError((_) {});
          _ad = null;
          state = BannerAdStatus.failed;
        },
      ),
    );

    _ad!.load().catchError((error) {
      debugPrint('[BannerAd] Error during load: $error');
      state = BannerAdStatus.failed;
    });
  }

  void _disposeAd() {
    try {
      _ad?.dispose().catchError((_) {});
    } catch (_) {}
    _ad = null;
  }

  /// Retries loading the banner ad after a failure.
  void reload() => _load();
}

/// Provider for [BannerAdNotifier].
///
/// Use [bannerAdProvider] to watch the [BannerAdStatus] and access the
/// [BannerAdNotifier.ad] instance for rendering via [AdWidget].
final bannerAdProvider = NotifierProvider<BannerAdNotifier, BannerAdStatus>(
  BannerAdNotifier.new,
);
