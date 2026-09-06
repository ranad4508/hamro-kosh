import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/shared_preferences_provider.dart';

const _themeModePrefsKey = 'hamro_kosh.theme_mode';

/// Persists the user's light/dark/system preference across launches.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.read(sharedPreferencesProvider).getString(
          _themeModePrefsKey,
        );
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeModePrefsKey, mode.name);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
