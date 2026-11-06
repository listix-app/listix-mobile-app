import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'src/app.dart';
import 'src/core/config/api_config.dart';
import 'src/core/config/app_environment.dart';
import 'src/core/network/auth_session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const ProviderScope(child: ListixApp()));
  if (AppEnvironmentConfig.adsEnabled) {
    unawaited(
      MobileAds.instance.initialize().catchError((e) {
        debugPrint('[MobileAds] Initialization failed: $e');
        return InitializationStatus({});
      }),
    );
  }
  if (ApiConfig.isConfigured) {
    unawaited(
      AuthSessionService.instance.initialize().catchError((e) {
        debugPrint('[AuthSessionService] Initialization failed: $e');
      }),
    );
  }
}
