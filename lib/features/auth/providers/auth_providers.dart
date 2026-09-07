import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// The raw Firebase auth stream — null means signed out. The router's
/// redirect logic listens to this via [GoRouterRefreshStream].
///
/// The `.timeout` is a deliberate safety net: with a correctly configured
/// Firebase project this stream emits within milliseconds, but with the
/// placeholder credentials this project ships before `flutterfire configure`
/// is run, the native plugin can hang without ever emitting an event or an
/// error — which would otherwise leave the splash screen (and the router
/// redirect that waits on this provider) stuck forever. Falling back to
/// "signed out" after a few seconds keeps the scaffold explorable.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref
      .watch(authRepositoryProvider)
      .authStateChanges()
      .timeout(const Duration(seconds: 5), onTimeout: (sink) => sink.add(null));
});

/// The signed-in member's Firestore profile (role, approval status, etc.),
/// re-fetched whenever the auth state changes.
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(user.uid);
});

/// Convenience derived provider used by the router redirect: defaults to
/// [UserRole.member] while the profile is still loading.
final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(userProfileProvider).value?.role ?? UserRole.member;
});
