import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/config/app_environment.dart';
import '../../data/ad_config.dart';

enum BannerAdStatus { loading, loaded, failed, disabled }

class BannerAdNotifier extends Notifier<BannerAdStatus> {
  BannerAd? _ad;

  BannerAd? get ad => _ad;

  @override
  BannerAdStatus build() {
    if (!ref.watch(adsEnabledProvider)) return BannerAdStatus.disabled;
    _load();
    ref.onDispose(_disposeAd);
    return BannerAdStatus.loading;
  }

  void _load() {
    if (!ref.read(adsEnabledProvider)) {
      _disposeAd();
      state = BannerAdStatus.disabled;
      return;
    }

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

  void reload() => _load();
}

class DetailBannerAdNotifier extends Notifier<BannerAdStatus> {
  BannerAd? _ad;

  BannerAd? get ad => _ad;

  @override
  BannerAdStatus build() {
    if (!ref.watch(adsEnabledProvider)) return BannerAdStatus.disabled;
    _load();
    ref.onDispose(_disposeAd);
    return BannerAdStatus.loading;
  }

  void _load() {
    if (!ref.read(adsEnabledProvider)) {
      _disposeAd();
      state = BannerAdStatus.disabled;
      return;
    }

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
          debugPrint('[DetailBannerAd] Failed to load: ${error.message}');
          ad.dispose().catchError((_) {});
          _ad = null;
          state = BannerAdStatus.failed;
        },
      ),
    );

    _ad!.load().catchError((error) {
      debugPrint('[DetailBannerAd] Error during load: $error');
      state = BannerAdStatus.failed;
    });
  }

  void _disposeAd() {
    try {
      _ad?.dispose().catchError((_) {});
    } catch (_) {}
    _ad = null;
  }

  void reload() => _load();
}

final bannerAdProvider = NotifierProvider<BannerAdNotifier, BannerAdStatus>(
  BannerAdNotifier.new,
);

final detailBannerAdProvider =
    NotifierProvider<DetailBannerAdNotifier, BannerAdStatus>(
      DetailBannerAdNotifier.new,
    );
