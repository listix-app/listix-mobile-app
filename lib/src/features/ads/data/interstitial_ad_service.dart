import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/storage/app_database.dart';
import 'ad_config.dart';

class InterstitialAdService {
  final AppDatabase _db;
  final Future<bool> Function(String adUnitId)? _adLauncher;
  final DateTime Function()? _clock;
  final bool _adsEnabled;

  static const String lastShownKey = 'last_interstitial_date';

  InterstitialAdService({
    AppDatabase? db,
    Future<bool> Function(String adUnitId)? adLauncher,
    DateTime Function()? clock,
    bool? adsEnabled,
  }) : _db = db ?? AppDatabase.instance,
       _adLauncher = adLauncher,
       _clock = clock,
       _adsEnabled = adsEnabled ?? AppEnvironmentConfig.adsEnabled;

  Future<bool> canShowToday() async {
    final lastShownStr = await _db.getSetting(lastShownKey);
    if (lastShownStr == null) return true;
    final lastDate = DateTime.tryParse(lastShownStr);
    if (lastDate == null) return true;
    final now = _clock?.call() ?? DateTime.now();
    final isSameDay =
        lastDate.year == now.year &&
        lastDate.month == now.month &&
        lastDate.day == now.day;
    return !isSameDay;
  }

  Future<bool> showInterstitialIfAllowed() async {
    if (!_adsEnabled) return false;

    final allowed = await canShowToday();
    if (!allowed) return false;

    if (_adLauncher != null) {
      final success = await _adLauncher(AdConfig.interstitialId);
      if (success) {
        await recordAdShown();
        return true;
      }
      return false;
    }

    final completer = Completer<bool>();
    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
              },
            );
            ad
                .show()
                .then((_) {
                  recordAdShown();
                  if (!completer.isCompleted) completer.complete(true);
                })
                .catchError((_) {
                  ad.dispose();
                  if (!completer.isCompleted) completer.complete(false);
                });
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  Future<void> recordAdShown([DateTime? date]) async {
    final now = date ?? (_clock?.call() ?? DateTime.now());
    await _db.setSetting(lastShownKey, now.toIso8601String());
  }
}

final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  return InterstitialAdService(adsEnabled: ref.watch(adsEnabledProvider));
});
