import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'src/app.dart';
import 'src/core/config/api_config.dart';
import 'src/core/config/app_environment.dart';
import 'src/core/network/auth_session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  if (AppEnvironmentConfig.adsEnabled) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('[MobileAds] Initialization failed: $e');
    }
  }
  if (ApiConfig.isConfigured) {
    try {
      await AuthSessionService.instance.initialize();
    } catch (e) {
      debugPrint('[AuthSessionService] Initialization failed: $e');
    }
  }
  runApp(const ProviderScope(child: ListixApp()));
}
