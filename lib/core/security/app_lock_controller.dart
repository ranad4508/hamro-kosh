import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../services/shared_preferences_provider.dart';

const _appLockEnabledPrefsKey = 'hamro_kosh.app_lock_enabled';

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Whether the user has opted into biometric/device-credential app lock,
/// persisted across launches. This is a new security feature added beyond
/// the original SRS artifact (SRS.md §58) — a natural fit for a financial
/// app, and cheap to wire at the app-shell level.
class AppLockSettingController extends Notifier<bool> {
  @override
  bool build() {
    return ref
        .read(sharedPreferencesProvider)
        .getBool(_appLockEnabledPrefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_appLockEnabledPrefsKey, enabled);
  }
}

final appLockSettingProvider =
    NotifierProvider<AppLockSettingController, bool>(
  AppLockSettingController.new,
);

/// Session-only unlocked/locked state. Starts locked whenever app-lock is
/// enabled; [AppLockGate] flips it after a successful biometric check.
class AppLockSessionController extends Notifier<bool> {
  @override
  bool build() => !ref.read(appLockSettingProvider);

  void markUnlocked() => state = true;

  void lock() {
    if (ref.read(appLockSettingProvider)) state = false;
  }
}

final appLockSessionProvider =
    NotifierProvider<AppLockSessionController, bool>(
  AppLockSessionController.new,
);

/// Attempts biometric/device-credential authentication. Returns false (never
/// throws) if the device has no supported hardware/enrollment — callers
/// should let the user continue with a PIN/password fallback in that case.
Future<bool> tryBiometricUnlock(LocalAuthentication auth) async {
  try {
    final supported = await auth.isDeviceSupported();
    final canCheck = await auth.canCheckBiometrics;
    if (!supported && !canCheck) return false;
    return await auth.authenticate(
      localizedReason: 'Unlock Hamro Kosh to continue',
    );
  } catch (_) {
    return false;
  }
}
