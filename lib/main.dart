import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'src/app.dart';
import 'src/core/config/app_environment.dart';
import 'src/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppEnvironmentConfig.adsEnabled) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('[MobileAds] Initialization failed: $e');
    }
  }
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('[SupabaseService] Initialization failed: $e');
  }
  runApp(const ProviderScope(child: ListixApp()));
}
