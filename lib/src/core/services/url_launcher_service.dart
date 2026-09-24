import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  final Future<bool> Function(Uri uri, {LaunchMode mode})? _customLauncher;

  const UrlLauncherService({
    Future<bool> Function(Uri uri, {LaunchMode mode})? customLauncher,
  }) : _customLauncher = customLauncher;

  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      if (_customLauncher != null) {
        return await _customLauncher(uri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> openEmail(String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: subject != null ? {'subject': subject} : null,
    );
    try {
      if (_customLauncher != null) {
        return await _customLauncher(uri);
      }
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}

final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return const UrlLauncherService();
});
