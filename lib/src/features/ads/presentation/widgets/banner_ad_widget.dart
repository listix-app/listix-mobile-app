import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controllers/banner_ad_controller.dart';

class BannerAdWidget extends ConsumerWidget {
  final bool isDetail;

  const BannerAdWidget({super.key, this.isDetail = false});

  static const double _bannerHeight = 50.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = isDetail
        ? ref.watch(detailBannerAdProvider)
        : ref.watch(bannerAdProvider);

    final ad = isDetail
        ? ref.read(detailBannerAdProvider.notifier).ad
        : ref.read(bannerAdProvider.notifier).ad;

    return switch (status) {
      BannerAdStatus.loading => const SizedBox(height: _bannerHeight),
      BannerAdStatus.loaded =>
        ad != null ? _buildAdContainer(ad) : const SizedBox.shrink(),
      BannerAdStatus.failed ||
      BannerAdStatus.disabled => const SizedBox.shrink(),
    };
  }

  Widget _buildAdContainer(BannerAd ad) {
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(key: ObjectKey(ad), ad: ad),
      ),
    );
  }
}
