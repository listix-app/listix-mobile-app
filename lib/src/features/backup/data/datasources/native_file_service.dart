import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class NativeFileService {
  Future<Map<String, dynamic>?> pickAndReadFile();
  Future<Map<String, dynamic>?> saveFile({
    required String fileName,
    required String content,
    String? mimeType,
  });
  Future<void> shareFile({
    required String fileName,
    required String content,
    String? mimeType,
    String? subject,
  });
}

class NativeFileServiceImpl implements NativeFileService {
  final MethodChannel _channel;
  final Future<ShareResult> Function(
    List<XFile> files, {
    String? subject,
    String? text,
  })?
  _shareFilesLauncher;

  static const String defaultChannelName =
      'com.nmenag.listix/native_file_system';

  NativeFileServiceImpl({
    MethodChannel? channel,
    Future<ShareResult> Function(
      List<XFile> files, {
      String? subject,
      String? text,
    })?
    shareFilesLauncher,
  }) : _channel = channel ?? const MethodChannel(defaultChannelName),
       _shareFilesLauncher = shareFilesLauncher;

  @override
  Future<Map<String, dynamic>?> pickAndReadFile() async {
    try {
      final res = await _channel.invokeMethod<dynamic>('openFile');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> saveFile({
    required String fileName,
    required String content,
    String? mimeType,
  }) async {
    try {
      final res = await _channel.invokeMethod<dynamic>('saveFile', {
        'fileName': fileName,
        'content': content,
        'mimeType': mimeType ?? 'application/json',
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> shareFile({
    required String fileName,
    required String content,
    String? mimeType,
    String? subject,
  }) async {
    final bytes = utf8.encode(content);
    final file = XFile.fromData(
      Uint8List.fromList(bytes),
      name: fileName,
      path: fileName,
      mimeType: mimeType ?? 'application/json',
    );

    if (_shareFilesLauncher != null) {
      await _shareFilesLauncher([file], subject: subject);
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [file], subject: subject),
      );
    }
  }
}

final nativeFileServiceProvider = Provider<NativeFileService>((ref) {
  return NativeFileServiceImpl();
});
