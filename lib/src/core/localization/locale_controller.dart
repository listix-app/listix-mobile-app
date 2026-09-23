import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    // Default to Spanish (primary language of user brief), or can be English
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

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return AppStrings(
    locale.languageCode == 'en' ? AppLanguage.en : AppLanguage.es,
  );
});
