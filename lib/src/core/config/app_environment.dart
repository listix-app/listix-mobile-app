import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { dev, preview, prod }

abstract final class AppEnvironmentConfig {
  static const String rawName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnvironment get current => parse(rawName);

  static AppEnvironment parse(String name) =>
      switch (name.trim().toLowerCase()) {
        'prod' || 'production' => AppEnvironment.prod,
        'preview' || 'staging' => AppEnvironment.preview,
        _ => AppEnvironment.dev,
      };

  // static bool get adsEnabled => current != AppEnvironment.prod;
  static bool get adsEnabled => false;
}

final adsEnabledProvider = Provider<bool>(
  (ref) => AppEnvironmentConfig.adsEnabled,
);

extension AppEnvironmentLabel on AppEnvironment {
  String get appTitle => switch (this) {
    AppEnvironment.prod => 'Listix',
    AppEnvironment.dev => 'Listix (dev)',
    AppEnvironment.preview => 'Listix (preview)',
  };

  String? get badgeLabel => switch (this) {
    AppEnvironment.prod => null,
    AppEnvironment.dev => 'DEV',
    AppEnvironment.preview => 'PREVIEW',
  };
}
