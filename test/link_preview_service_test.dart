import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:listix/src/core/services/link_preview_service.dart';

LinkPreviewService _serviceReturning(String body, {int status = 200}) =>
    LinkPreviewService(
      client: MockClient((_) async => http.Response(body, status)),
    );

void main() {
  group('LinkPreviewService', () {
    test('reads og:image regardless of attribute order', () async {
      final service = _serviceReturning(
        '<meta content="https://img.test/a.png" property="og:image">',
      );
      expect(
        await service.fetchImageUrl('https://shop.test/p'),
        'https://img.test/a.png',
      );
    });

    test('resolves relative paths and decodes ampersands', () async {
      final service = _serviceReturning(
        "<meta name='twitter:image' content='/img/a.png?x=1&amp;y=2'>",
      );
      expect(
        await service.fetchImageUrl('https://shop.test/p/1'),
        'https://shop.test/img/a.png?x=1&y=2',
      );
    });

    test('prefers og:image over twitter:image', () async {
      final service = _serviceReturning(
        '<meta name="twitter:image" content="https://img.test/t.png">'
        '<meta property="og:image" content="https://img.test/o.png">',
      );
      expect(
        await service.fetchImageUrl('https://shop.test'),
        'https://img.test/o.png',
      );
    });

    test('skips empty and non-web image values', () async {
      final service = _serviceReturning(
        '<meta property="og:image" content="">'
        '<meta property="og:image:url" content="data:image/png;base64,AA">'
        '<meta property="description" content="x">'
        '<meta charset="utf-8">',
      );
      expect(await service.fetchImageUrl('https://shop.test'), isNull);
    });

    test('uses the link itself when it points to an image', () async {
      final service = LinkPreviewService(
        client: MockClient(
          (_) async => http.Response(
            'binary',
            200,
            headers: {'content-type': 'image/png'},
          ),
        ),
      );
      expect(
        await service.fetchImageUrl('https://img.test/a.png'),
        'https://img.test/a.png',
      );
    });

    test('returns null for non-200 responses', () async {
      final service = _serviceReturning('x', status: 404);
      expect(await service.fetchImageUrl('https://shop.test'), isNull);
    });

    test('returns null for invalid links', () async {
      final service = _serviceReturning('x');
      expect(await service.fetchImageUrl('not a link'), isNull);
    });

    test('returns null when the request fails', () async {
      final service = LinkPreviewService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(await service.fetchImageUrl('https://shop.test'), isNull);
    });

    test('provider exposes a service', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(linkPreviewServiceProvider), isNotNull);
    });
  });
}
