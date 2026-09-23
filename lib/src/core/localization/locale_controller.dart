import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_strings.dart';
import 'generated/app_localizations.dart';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('es');
  }

  void setLanguage(AppLanguage language) {
    state = Locale(language.name);
  }

  void toggleLanguage() {
    state = state.languageCode == 'es'
        ? const Locale('en')
        : const Locale('es');
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return lookupAppLocalizations(locale);
});

final stringsProvider = Provider<AppStrings>((ref) {
  final l10n = ref.watch(appLocalizationsProvider);
  return AppStrings.fromLocalizations(l10n);
});
