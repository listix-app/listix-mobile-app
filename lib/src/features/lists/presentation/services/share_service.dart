import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/shopping_list.dart';

typedef UrlLauncherFn = Future<bool> Function(Uri url, {LaunchMode mode});
typedef SystemShareFn =
    Future<ShareResult> Function(
      String text, {
      String? subject,
      Rect? sharePositionOrigin,
    });

class ShareService {
  final UrlLauncherFn _urlLauncher;
  final SystemShareFn? _systemShare;

  const ShareService({UrlLauncherFn? urlLauncher, SystemShareFn? systemShare})
    : _urlLauncher = urlLauncher ?? launchUrl,
      _systemShare = systemShare;

  static String formatListForSharing({
    required ShoppingList list,
    required String createdWithText,
    String? inviteLinkText,
    String? pendingSectionTitle,
    String? completedSectionTitle,
    String? emptyListText,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *${list.name}*');

    final pending = list.items.where((i) => !i.isCompleted).toList();
    final completed = list.items.where((i) => i.isCompleted).toList();

    if (list.items.isEmpty) {
      buffer.writeln();
      buffer.writeln(emptyListText ?? '• (Empty)');
    } else {
      if (pending.isNotEmpty) {
        buffer.writeln();
        if (pendingSectionTitle != null && pendingSectionTitle.isNotEmpty) {
          buffer.writeln('$pendingSectionTitle (${pending.length}):');
        }
        for (final item in pending) {
          buffer.writeln('• ${item.title}');
        }
      }

      if (completed.isNotEmpty) {
        buffer.writeln();
        if (completedSectionTitle != null && completedSectionTitle.isNotEmpty) {
          buffer.writeln('$completedSectionTitle (${completed.length}):');
        }
        for (final item in completed) {
          buffer.writeln('✓ ${item.title}');
        }
      }
    }

    if (inviteLinkText != null && inviteLinkText.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(inviteLinkText);
    }

    buffer.writeln();
    buffer.write(createdWithText);
    return buffer.toString();
  }

  Future<ShareResult> shareWithSystem({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    if (_systemShare != null) {
      return await _systemShare(
        text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );
    }
    return await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
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
