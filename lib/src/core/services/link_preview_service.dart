import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class LinkPreviewService {
  static const _timeout = Duration(seconds: 6);
  static const _previewKeys = ['og:image', 'og:image:url', 'twitter:image'];

  final http.Client _client;

  LinkPreviewService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> fetchImageUrl(String link) async {
    final pageUri = Uri.tryParse(link.trim());
    if (pageUri == null || !pageUri.hasAuthority) return null;
    try {
      final response = await _client
          .get(pageUri, headers: const {'User-Agent': 'Mozilla/5.0 Listix'})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.toLowerCase().startsWith('image/')) {
        return pageUri.toString();
      }
      return _extractImage(response.body, pageUri);
    } catch (_) {
      return null;
    }
  }

  String? _extractImage(String html, Uri pageUri) {
    final metaTags = RegExp(
      r'<meta\s[^>]*>',
      caseSensitive: false,
    ).allMatches(html);
    final found = <String, String>{};
    for (final tag in metaTags) {
      final attributes = _attributesOf(tag.group(0)!);
      final key = attributes['property'] ?? attributes['name'];
      final content = attributes['content'];
      if (key != null && content != null && content.isNotEmpty) {
        found.putIfAbsent(key.toLowerCase(), () => content);
      }
    }
    for (final key in _previewKeys) {
      final content = found[key];
      if (content == null) continue;
      final resolved = pageUri.resolve(content.replaceAll('&amp;', '&'));
      if (resolved.scheme == 'http' || resolved.scheme == 'https') {
        return resolved.toString();
      }
    }
    return null;
  }

  Map<String, String> _attributesOf(String tag) => {
    for (final match in RegExp(
      r'''([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')''',
    ).allMatches(tag))
      match.group(1)!.toLowerCase(): match.group(2) ?? match.group(3) ?? '',
  };
}

final linkPreviewServiceProvider = Provider<LinkPreviewService>((ref) {
  return LinkPreviewService();
});
