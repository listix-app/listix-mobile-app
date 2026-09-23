import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/shopping_list.dart';

typedef UrlLauncherFn = Future<bool> Function(Uri url, {LaunchMode mode});

class ShareService {
  final UrlLauncherFn _urlLauncher;

  const ShareService({UrlLauncherFn? urlLauncher})
    : _urlLauncher = urlLauncher ?? launchUrl;

  static String formatListForSharing({
    required ShoppingList list,
    required String createdWithText,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *${list.name}*');
    buffer.writeln();

    final pending = list.items.where((i) => !i.isCompleted).toList();
    final completed = list.items.where((i) => i.isCompleted).toList();

    if (pending.isNotEmpty) {
      for (final item in pending) {
        buffer.writeln('• ${item.title}');
      }
    }

    if (completed.isNotEmpty) {
      if (pending.isNotEmpty) buffer.writeln();
      for (final item in completed) {
        buffer.writeln('✓ ${item.title}');
      }
    }

    if (list.items.isEmpty) {
      buffer.writeln('• (Empty)');
    }

    buffer.writeln();
    buffer.write(createdWithText);
    return buffer.toString();
  }

  Future<bool> shareToWhatsApp(String text) async {
    final encoded = Uri.encodeComponent(text);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encoded');
    try {
      final launched = await _urlLauncher(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final webUri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');
        return await _urlLauncher(webUri, mode: LaunchMode.externalApplication);
      }
      return launched;
    } catch (_) {
      try {
        final webUri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');
        return await _urlLauncher(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> shareToGmail({
    required String subject,
    required String body,
  }) async {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final uri = Uri.parse('mailto:?subject=$encodedSubject&body=$encodedBody');
    try {
      return await _urlLauncher(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

final shareServiceProvider = Provider<ShareService>((ref) {
  return const ShareService();
});
