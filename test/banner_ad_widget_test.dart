import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:listix/src/features/ads/data/ad_config.dart';
import 'package:listix/src/features/ads/presentation/controllers/banner_ad_controller.dart';
import 'package:listix/src/features/ads/presentation/widgets/banner_ad_widget.dart';

int lastAdId = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (
          MethodCall call,
        ) async {
          if (call.method == 'loadBannerAd' || call.method == 'loadInterstitialAd') {
            lastAdId = call.arguments['adId'] as int;
            return null;
          } else if (call.method == 'disposeAd' || call.method == 'showAdWithoutView') {
            return null;
          }
          return null;
        });
  });

  group('AdConfig Tests', () {
    test('AdConfig provides valid official test IDs', () {
      expect(AdConfig.androidAppId, 'ca-app-pub-3940256099942544~3347511713');
      expect(AdConfig.iosAppId, 'ca-app-pub-3940256099942544~1458002511');
      expect(AdConfig.bannerId, isNotEmpty);
    });
  });

  group('BannerAdNotifier and BannerAdWidget Tests', () {
    testWidgets('BannerAdWidget renders loading placeholder initially', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(bottomNavigationBar: BannerAdWidget()),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.any((box) => box.height == 50.0), isTrue);
    });

    testWidgets(
      'BannerAdNotifier updates to loaded state on onAdLoaded event',
      (tester) async {
        late ProviderContainer container;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return const MaterialApp(
                  home: Scaffold(bottomNavigationBar: BannerAdWidget()),
                );
              },
            ),
          ),
        );

        final notifier = container.read(bannerAdProvider.notifier);
        expect(notifier.ad, isNotNull);

        final ByteData message = instanceManager.channel.codec.encodeMethodCall(
          MethodCall('onAdEvent', {
            'adId': lastAdId,
            'eventName': 'onAdLoaded',
          }),
        );
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              instanceManager.channel.name,
              message,
              (data) {},
            );

        await tester.pumpAndSettle();

        expect(container.read(bannerAdProvider), BannerAdStatus.loaded);
        expect(find.byType(AdWidget), findsOneWidget);
      },
    );

    testWidgets(
      'BannerAdNotifier updates to failed state on onAdFailedToLoad event',
      (tester) async {
        late ProviderContainer container;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return const MaterialApp(
                  home: Scaffold(bottomNavigationBar: BannerAdWidget()),
                );
              },
            ),
          ),
        );

        final notifier = container.read(bannerAdProvider.notifier);

        final error = LoadAdError(1, 'domain', 'Network timeout', null);
        final ByteData message = instanceManager.channel.codec.encodeMethodCall(
          MethodCall('onAdEvent', {
            'adId': lastAdId,
            'eventName': 'onAdFailedToLoad',
            'loadAdError': error,
          }),
        );
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              instanceManager.channel.name,
              message,
              (data) {},
            );

        await tester.pumpAndSettle();

        expect(container.read(bannerAdProvider), BannerAdStatus.failed);
        expect(notifier.ad, isNull);
        expect(find.byType(AdWidget), findsNothing);

        notifier.reload();
        expect(container.read(bannerAdProvider), BannerAdStatus.loading);
        expect(notifier.ad, isNotNull);
      },
    );

    testWidgets(
      'BannerAdNotifier handles load failure gracefully and disposes',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(instanceManager.channel, (
              MethodCall call,
            ) async {
              if (call.method == 'loadBannerAd') {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Failed to load',
                );
              }
              return null;
            });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final status = container.read(bannerAdProvider);
        expect(status, BannerAdStatus.loading);

        await tester.pump();

        expect(container.read(bannerAdProvider), BannerAdStatus.failed);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(instanceManager.channel, (
              MethodCall call,
            ) async {
              if (call.method == 'loadBannerAd' || call.method == 'loadInterstitialAd') {
                lastAdId = call.arguments['adId'] as int;
                return null;
              } else if (call.method == 'disposeAd' || call.method == 'showAdWithoutView') {
                return null;
              }
              return null;
            });
      },
    );
  });
}
