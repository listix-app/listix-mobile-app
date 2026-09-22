import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/features/ads/data/datasources/admob_unit_ids.dart';
import 'package:listix/src/features/ads/data/repositories/mock_admob_service.dart';
import 'package:listix/src/features/ads/domain/entities/mock_admob_campaign.dart';
import 'package:listix/src/features/ads/presentation/controllers/admob_controller.dart';
import 'package:listix/src/features/ads/presentation/widgets/admob_banner_widget.dart';
import 'package:listix/src/features/ads/presentation/widgets/admob_interstitial_dialog.dart';

void main() {
  group('MockAdmobService unit tests', () {
    late MockAdmobService service;

    setUp(() {
      service = MockAdmobService(simulatedLatency: Duration.zero);
    });

    tearDown(() {
      service.dispose();
    });

    test('initialize loads banner and interstitial ads', () async {
      expect(service.isInitialized, isFalse);
      expect(service.isInterstitialReady, isFalse);

      await service.initialize();

      expect(service.isInitialized, isTrue);
      expect(service.bannerState.isLoaded, isTrue);
      expect(service.bannerState.adUnitId, AdmobUnitIds.bannerTestUnitId);
      expect(service.isInterstitialReady, isTrue);
      expect(
        service.interstitialState.adUnitId,
        AdmobUnitIds.interstitialTestUnitId,
      );
    });

    test('recordBannerClick increments banner click count', () async {
      await service.initialize();
      expect(service.bannerState.clicksCount, 0);

      service.recordBannerClick();
      expect(service.bannerState.clicksCount, 1);

      service.recordBannerClick();
      expect(service.bannerState.clicksCount, 2);
    });

    test('loadBannerAd handles simulated errors', () async {
      final errorService = MockAdmobService(
        simulatedLatency: Duration.zero,
        shouldSimulateErrors: true,
      );

      final success = await errorService.loadBannerAd();
      expect(success, isFalse);
      expect(errorService.bannerState.isFailed, isTrue);
      expect(errorService.bannerState.errorMessage, contains('Error code 3'));

      errorService.dispose();
    });

    test('loadInterstitialAd handles simulated errors', () async {
      final errorService = MockAdmobService(
        simulatedLatency: Duration.zero,
        shouldSimulateErrors: true,
      );

      final success = await errorService.loadInterstitialAd();
      expect(success, isFalse);
      expect(errorService.interstitialState.isFailed, isTrue);
      expect(
        errorService.interstitialState.errorMessage,
        contains('Error code 0'),
      );

      errorService.dispose();
    });

    test('campaign rotation works as expected', () {
      final camp1 = service.getCurrentCampaign();
      final camp2 = service.getCurrentCampaign(next: true);
      expect(camp1.id, isNot(equals(camp2.id)));
    });
  });

  group('AdMob Presentation Widgets', () {
    testWidgets('AdmobBannerWidget renders ad badge and campaign metadata', (
      tester,
    ) async {
      final service = MockAdmobService(simulatedLatency: Duration.zero);
      await service.initialize();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [admobServiceProvider.overrideWithValue(service)],
          child: const MaterialApp(home: Scaffold(body: AdmobBannerWidget())),
        ),
      );

      await tester.pump();

      // Verify Ad badge is rendered
      expect(find.text('Ad'), findsOneWidget);

      // Verify campaign info is rendered
      final campaign = service.getCurrentCampaign();
      expect(find.text(campaign.sponsorName), findsOneWidget);
      expect(find.text(campaign.title), findsOneWidget);
      expect(find.text(campaign.ctaText), findsOneWidget);

      // Tap banner to verify click recording
      await tester.tap(find.byType(AdmobBannerWidget));
      await tester.pump();

      expect(service.bannerState.clicksCount, 1);
      service.dispose();
    });

    testWidgets(
      'AdmobInterstitialDialog displays countdown and can be skipped',
      (tester) async {
        bool closed = false;
        bool actionTaken = false;

        final campaign = MockAdmobCampaign.sampleCampaigns[0];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdmobInterstitialDialog(
                campaign: campaign,
                adUnitId: AdmobUnitIds.androidInterstitial,
                countdownSeconds: 0, // Instant skip for test
                onClose: () => closed = true,
                onAction: () => actionTaken = true,
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify AdMob header and campaign content
        expect(find.text('Google AdMob • Test Interstitial'), findsOneWidget);
        expect(find.text(campaign.sponsorName), findsOneWidget);
        expect(find.text(campaign.title), findsOneWidget);
        expect(find.text(campaign.ctaText), findsOneWidget);

        // Verify Close button is present (since countdownSeconds was 0)
        expect(find.text('Cerrar'), findsOneWidget);
        await tester.tap(find.text('Cerrar'));
        await tester.pump();

        expect(closed, isTrue);

        // Tap CTA button
        await tester.tap(find.text(campaign.ctaText));
        await tester.pump();

        expect(actionTaken, isTrue);
      },
    );
  });
}
