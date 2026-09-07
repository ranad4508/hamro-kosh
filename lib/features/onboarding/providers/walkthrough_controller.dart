import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/shared_preferences_provider.dart';

const _prefsKey = 'hamro_kosh.member_walkthrough_seen';

/// Tracks which member accounts have already seen (or skipped) the member
/// walkthrough — scoped per uid, not per device, so a shared device with
/// multiple accounts still shows it once per new member. Read synchronously
/// (SharedPreferences is loaded before `runApp`, see `bootstrap.dart`) so
/// the router's redirect can gate on it without an async round-trip, the
/// same way `ThemeModeController` reads its own preference.
class WalkthroughSeenController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return (prefs.getStringList(_prefsKey) ?? const []).toSet();
  }

  bool hasSeen(String uid) => state.contains(uid);

  Future<void> markSeen(String uid) async {
    if (state.contains(uid)) return;
    state = {...state, uid};
    await ref.read(sharedPreferencesProvider).setStringList(_prefsKey, state.toList());
  }
}

final walkthroughSeenControllerProvider =
    NotifierProvider<WalkthroughSeenController, Set<String>>(
      WalkthroughSeenController.new,
    );
