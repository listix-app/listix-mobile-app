import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/admob_ad_state.dart';
import '../../domain/entities/mock_admob_campaign.dart';
import '../../domain/repositories/admob_service.dart';
import '../../presentation/widgets/admob_interstitial_dialog.dart';
import '../datasources/admob_unit_ids.dart';

/// Production-ready mock implementation of [AdmobService].
/// Simulates AdMob banner and interstitial lifecycles, ad request latency,
/// impressions, clicks, and full-screen presentations without native SDK baggage.
class MockAdmobService implements AdmobService {
  static Duration defaultLatency = const Duration(milliseconds: 350);

  final Duration simulatedLatency;
  final bool shouldSimulateErrors;

  bool _isInitialized = false;
  int _campaignIndex = 0;

  AdmobAdState _bannerState = const AdmobAdState();
  AdmobAdState _interstitialState = const AdmobAdState();

  final _bannerController = StreamController<AdmobAdState>.broadcast();
  final _interstitialController = StreamController<AdmobAdState>.broadcast();

  MockAdmobService({
    Duration? simulatedLatency,
    this.shouldSimulateErrors = false,
  }) : simulatedLatency = simulatedLatency ?? defaultLatency;

  @override
  bool get isInitialized => _isInitialized;

  @override
  AdmobAdState get bannerState => _bannerState;

  @override
  AdmobAdState get interstitialState => _interstitialState;

  @override
  Stream<AdmobAdState> get bannerStateStream => _bannerController.stream;

  @override
  Stream<AdmobAdState> get interstitialStateStream =>
      _interstitialController.stream;

  @override
  bool get isInterstitialReady =>
      _interstitialState.status == AdLoadStatus.loaded;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Automatically load initial banner and preload interstitial ad
    await Future.wait([loadBannerAd(), loadInterstitialAd()]);
  }

  @override
  Future<bool> loadBannerAd({String? adUnitId}) async {
    final unitId = adUnitId ?? AdmobUnitIds.bannerTestUnitId;
    _updateBannerState(
      _bannerState.copyWith(
        status: AdLoadStatus.loading,
        adUnitId: unitId,
        errorMessage: null,
      ),
    );

    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    if (shouldSimulateErrors) {
      _updateBannerState(
        _bannerState.copyWith(
          status: AdLoadStatus.failed,
          errorMessage: 'Error code 3: No ad inventory available (Simulated).',
        ),
      );
      return false;
    }

    _updateBannerState(
      _bannerState.copyWith(
        status: AdLoadStatus.loaded,
        adUnitId: unitId,
        impressionsCount: _bannerState.impressionsCount + 1,
      ),
    );
    return true;
  }

  @override
  Future<bool> loadInterstitialAd({String? adUnitId}) async {
    final unitId = adUnitId ?? AdmobUnitIds.interstitialTestUnitId;
    _updateInterstitialState(
      _interstitialState.copyWith(
        status: AdLoadStatus.loading,
        adUnitId: unitId,
        errorMessage: null,
      ),
    );

    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    if (shouldSimulateErrors) {
      _updateInterstitialState(
        _interstitialState.copyWith(
          status: AdLoadStatus.failed,
          errorMessage: 'Error code 0: Ad request network timeout (Simulated).',
        ),
      );
      return false;
    }

    _updateInterstitialState(
      _interstitialState.copyWith(
        status: AdLoadStatus.loaded,
        adUnitId: unitId,
      ),
    );
    return true;
  }

  @override
  Future<bool> showInterstitialAd(
    BuildContext context, {
    VoidCallback? onDismissed,
    VoidCallback? onAdClicked,
  }) async {
    if (!isInterstitialReady) {
      // Try to load one quickly if not ready
      final loaded = await loadInterstitialAd();
      if (!loaded || !context.mounted) return false;
    }

    final campaign = getCurrentCampaign(next: true);

    _updateInterstitialState(
      _interstitialState.copyWith(
        status: AdLoadStatus.opened,
        impressionsCount: _interstitialState.impressionsCount + 1,
      ),
    );

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AdmobInterstitialDialog(
          campaign: campaign,
          adUnitId:
              _interstitialState.adUnitId ??
              AdmobUnitIds.interstitialTestUnitId,
          onClose: () {
            Navigator.of(dialogContext).pop(false);
          },
          onAction: () {
            _updateInterstitialState(
              _interstitialState.copyWith(
                clicksCount: _interstitialState.clicksCount + 1,
              ),
            );
            onAdClicked?.call();
            Navigator.of(dialogContext).pop(true);
          },
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );

    _updateInterstitialState(
      _interstitialState.copyWith(status: AdLoadStatus.dismissed),
    );

    onDismissed?.call();

    // AdMob best practice: preload next interstitial in the background
    unawaited(loadInterstitialAd());

    return result ?? false;
  }

  @override
  MockAdmobCampaign getCurrentCampaign({bool next = false}) {
    if (next) {
      _campaignIndex =
          (_campaignIndex + 1) % MockAdmobCampaign.sampleCampaigns.length;
    }
    return MockAdmobCampaign.sampleCampaigns[_campaignIndex];
  }

  @override
  void recordBannerClick() {
    _updateBannerState(
      _bannerState.copyWith(clicksCount: _bannerState.clicksCount + 1),
    );
  }

  void _updateBannerState(AdmobAdState state) {
    _bannerState = state;
    if (!_bannerController.isClosed) {
      _bannerController.add(state);
    }
  }

  void _updateInterstitialState(AdmobAdState state) {
    _interstitialState = state;
    if (!_interstitialController.isClosed) {
      _interstitialController.add(state);
    }
  }

  @override
  void dispose() {
    _bannerController.close();
    _interstitialController.close();
  }
}
