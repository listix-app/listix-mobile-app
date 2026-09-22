import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_admob_service.dart';
import '../../domain/entities/admob_ad_state.dart';
import '../../domain/repositories/admob_service.dart';

/// Provider for the singleton [AdmobService].
final admobServiceProvider = Provider<AdmobService>((ref) {
  final bool isRunningInTest = WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  final service = MockAdmobService(
    simulatedLatency: isRunningInTest ? Duration.zero : null,
  );
  // Auto-initialize
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider listening to Banner Ad state changes.
final bannerAdStateProvider = StreamProvider<AdmobAdState>((ref) {
  final service = ref.watch(admobServiceProvider);
  return service.bannerStateStream;
});

/// Stream provider listening to Interstitial Ad state changes.
final interstitialAdStateProvider = StreamProvider<AdmobAdState>((ref) {
  final service = ref.watch(admobServiceProvider);
  return service.interstitialStateStream;
});

/// Controller exposing actions for showing AdMob ads.
class AdmobController {
  final AdmobService _service;

  AdmobController(this._service);

  bool get isInterstitialReady => _service.isInterstitialReady;

  Future<bool> showInterstitial(
    BuildContext context, {
    VoidCallback? onDismissed,
    VoidCallback? onAdClicked,
  }) {
    return _service.showInterstitialAd(
      context,
      onDismissed: onDismissed,
      onAdClicked: onAdClicked,
    );
  }

  Future<bool> reloadBanner() {
    return _service.loadBannerAd();
  }

  void recordBannerClick() {
    _service.recordBannerClick();
  }
}

/// Provider for [AdmobController].
final admobControllerProvider = Provider<AdmobController>((ref) {
  final service = ref.watch(admobServiceProvider);
  return AdmobController(service);
});
