import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/banner_ad_controller.dart';

/// A reusable Banner Ad widget backed by the real Google Mobile Ads SDK.
///
/// States:
/// • **loading** — shows a placeholder `SizedBox` with the banner height.
/// • **loaded**  — renders the real ad via [AdWidget].
/// • **failed**  — renders `SizedBox.shrink()` so the UI is not broken.
///
/// The ad lifecycle is managed entirely by [BannerAdNotifier]; this widget
/// simply observes the state and displays the appropriate UI.
class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({super.key});

  /// Standard banner height in logical pixels.
  static const double _bannerHeight = 50.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(bannerAdProvider);
    final notifier = ref.read(bannerAdProvider.notifier);

    return switch (status) {
      BannerAdStatus.loading => const SizedBox(height: _bannerHeight),
      BannerAdStatus.failed => const SizedBox.shrink(),
      BannerAdStatus.loaded => _buildAdContainer(notifier.ad!),
    };
  }

  Widget _buildAdContainer(BannerAd ad) {
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
