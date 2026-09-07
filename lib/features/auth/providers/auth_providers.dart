import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../../../core/services/cloud_functions_service.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    ref.watch(cloudFunctionsServiceProvider),
  );
});

/// Wraps [FirebaseAuth.authStateChanges] with a one-time startup fallback:
/// if Firebase never emits an initial event within 5 seconds (a
/// misconfigured or placeholder Firebase project hanging forever, rather
/// than a real "signed out"), this emits `null` once so the splash screen
/// doesn't wait indefinitely — the app stays explorable before real
/// credentials are configured. Once a genuine event arrives, the fallback
/// never fires. State lives inside this generator's own `StreamController`
/// rather than as mutable state in a provider body, so a provider rebuild
/// can't leave a stale flag behind.
Stream<User?> _withStartupFallback(Stream<User?> source) {
  late final StreamController<User?> controller;
  StreamSubscription<User?>? subscription;
  var settled = false;
  Timer? fallbackTimer;

  controller = StreamController<User?>(
    onListen: () {
      subscription = source.listen(
        (event) {
          settled = true;
          fallbackTimer?.cancel();
          controller.add(event);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
      fallbackTimer = Timer(const Duration(seconds: 5), () {
        if (!settled) {
          settled = true;
          controller.add(null);
        }
      });
    },
    onCancel: () {
      fallbackTimer?.cancel();
      subscription?.cancel();
    },
  );
  return controller.stream;
}

final authStateProvider = StreamProvider<User?>((ref) {
  return _withStartupFallback(
    ref.watch(authRepositoryProvider).authStateChanges(),
  );
});

final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(uid);
});

/// Derived, synchronous role read for the router/UI gating — defaults to
/// [UserRole.member] while the profile is still loading. Safe for redirect
/// decisions (which re-run once the real value arrives); anything making an
/// actual *authorization* decision should watch [userProfileProvider]
/// directly instead of relying on this default.
final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(userProfileProvider).value?.role ?? UserRole.member;
});

/// Where the signed-in user's account currently stands (SRS §35) — see
/// [AccountStatus]'s doc for what each state means. `null` while either the
/// auth state or the profile is still loading.
final accountStatusProvider = Provider<AccountStatus?>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(userProfileProvider);
  if (authState.isLoading || profileState.isLoading) return null;
  if (authState.value == null) return null;

  final profile = profileState.value;
  if (profile == null) return AccountStatus.noProfile;
  return profile.status;
});
