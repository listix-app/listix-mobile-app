import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/admob_banner_size.dart';
import '../../domain/entities/mock_admob_campaign.dart';
import '../controllers/admob_controller.dart';

/// Interactive Google AdMob Banner Ad widget.
/// Renders standard or adaptive banner ad dimensions with AdMob badges,
/// sponsored metadata, and simulated click interactions.
class AdmobBannerWidget extends ConsumerStatefulWidget {
  final AdmobBannerSize size;
  final VoidCallback? onAdClicked;

  const AdmobBannerWidget({
    super.key,
    this.size = AdmobBannerSize.adaptive,
    this.onAdClicked,
  });

  @override
  ConsumerState<AdmobBannerWidget> createState() => _AdmobBannerWidgetState();
}

class _AdmobBannerWidgetState extends ConsumerState<AdmobBannerWidget> {
  late MockAdmobCampaign _campaign;

  @override
  void initState() {
    super.initState();
    _campaign = ref.read(admobServiceProvider).getCurrentCampaign();
  }

  void _handleClick() {
    ref.read(admobControllerProvider).recordBannerClick();
    widget.onAdClicked?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AdMob Click: "${_campaign.title}" (${_campaign.sponsorName})',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adService = ref.watch(admobServiceProvider);
    final bannerAsync = ref.watch(bannerAdStateProvider);
    final currentState = bannerAsync.asData?.value ?? adService.bannerState;

    // Fixed height matching selected banner size
    final height = widget.size.height;

    if (currentState.isFailed) {
      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            const Text(
              'No se pudo cargar el banner de AdMob',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ref.read(admobControllerProvider).reloadBanner(),
              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (currentState.isLoading) {
      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Cargando AdMob Banner...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleClick,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Ad icon / logo
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _campaign.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _campaign.icon,
                    size: 22,
                    color: _campaign.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),

                // Content info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Ad tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B), // Amber 500
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'Ad',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _campaign.sponsorName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _campaign.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // CTA button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _campaign.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _campaign.ctaText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
