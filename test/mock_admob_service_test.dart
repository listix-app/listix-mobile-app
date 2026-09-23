import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/features/ads/data/datasources/admob_unit_ids.dart';
import 'package:listix/src/features/ads/data/repositories/mock_admob_service.dart';
import 'package:listix/src/features/ads/domain/entities/admob_ad_state.dart';
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

      // Re-initialize is a no-op
      await service.initialize();
      expect(service.isInitialized, isTrue);
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

    test('AdmobController delegates methods correctly', () async {
      final controller = AdmobController(service);
      expect(controller.isInterstitialReady, isFalse);

      await controller.reloadBanner();
      expect(service.bannerState.isLoaded, isTrue);

      controller.recordBannerClick();
      expect(service.bannerState.clicksCount, 1);
    });
  });

  group('AdMob Presentation Widgets & Dialogs', () {
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

    testWidgets('AdmobBannerWidget renders loading state', (tester) async {
      final service = MockAdmobService(simulatedLatency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            admobServiceProvider.overrideWithValue(service),
            bannerAdStateProvider.overrideWith(
              (ref) => Stream.value(
                const AdmobAdState(status: AdLoadStatus.loading),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: AdmobBannerWidget())),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando AdMob Banner...'), findsOneWidget);
      service.dispose();
    });

    testWidgets('AdmobBannerWidget renders failed state and retries', (
      tester,
    ) async {
      final service = MockAdmobService(simulatedLatency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            admobServiceProvider.overrideWithValue(service),
            bannerAdStateProvider.overrideWith(
              (ref) => Stream.value(
                const AdmobAdState(
                  status: AdLoadStatus.failed,
                  errorMessage: 'Error simulated',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: AdmobBannerWidget())),
        ),
      );

      await tester.pump();
      expect(find.text('No se pudo cargar el banner de AdMob'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
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

        expect(find.text('Google AdMob • Test Interstitial'), findsOneWidget);
        expect(find.text(campaign.sponsorName.toUpperCase()), findsOneWidget);
        expect(find.text(campaign.title), findsOneWidget);
        expect(find.text(campaign.ctaText), findsOneWidget);

        expect(find.text('Cerrar'), findsOneWidget);
        await tester.tap(find.text('Cerrar'));
        await tester.pump();

        expect(closed, isTrue);

        await tester.tap(find.text(campaign.ctaText));
        await tester.pump();

        expect(actionTaken, isTrue);
      },
    );

    testWidgets('AdmobInterstitialDialog countdown timer ticks and completes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdmobInterstitialDialog(
              campaign: MockAdmobCampaign.sampleCampaigns[0],
              adUnitId: AdmobUnitIds.androidInterstitial,
              countdownSeconds: 2,
              onClose: () {},
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Saltar en 2s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Saltar en 1s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Cerrar'), findsOneWidget);
    });

    testWidgets(
      'showInterstitialAd flow presents dialog and triggers callbacks',
      (tester) async {
        final service = MockAdmobService(simulatedLatency: Duration.zero);
        await service.initialize();

        bool dismissed = false;
        bool clicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      service.showInterstitialAd(
                        context,
                        onDismissed: () => dismissed = true,
                        onAdClicked: () => clicked = true,
                      );
                    },
                    child: const Text('Show Ad'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Ad'));
        await tester.pumpAndSettle();

        expect(find.byType(AdmobInterstitialDialog), findsOneWidget);

        // Tap CTA inside interstitial
        final campaign = service.getCurrentCampaign();
        await tester.tap(find.text(campaign.ctaText));
        await tester.pumpAndSettle();

        expect(clicked, isTrue);
        expect(dismissed, isTrue);
        service.dispose();
      },
    );

    testWidgets(
      'showInterstitialAd returns false when service fails to load ad',
      (tester) async {
        final failingService = MockAdmobService(
          simulatedLatency: Duration.zero,
          shouldSimulateErrors: true,
        );

        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await failingService.showInterstitialAd(context);
                    },
                    child: const Text('Show Failing Ad'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Failing Ad'));
        await tester.pumpAndSettle();

        expect(result, isFalse);
        failingService.dispose();
      },
    );
  });
}
