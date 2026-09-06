import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/shared_preferences_provider.dart';

const _localePrefsKey = 'hamro_kosh.locale';

/// Supported app locales. `null` means "follow system".
const supportedAppLocales = [Locale('en'), Locale('ne')];

/// Persists the user's language preference (English / Nepali / system).
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final stored =
        ref.read(sharedPreferencesProvider).getString(_localePrefsKey);
    if (stored == null) return null;
    return supportedAppLocales.firstWhere(
      (locale) => locale.languageCode == stored,
      orElse: () => supportedAppLocales.first,
    );
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localePrefsKey);
    } else {
      await prefs.setString(_localePrefsKey, locale.languageCode);
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
