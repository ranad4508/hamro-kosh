import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/app_user.dart';
import 'route_paths.dart';

const _authRoutes = {
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.forgotPassword,
};

/// The router's entire access-control policy (SRS §51 rule 9), extracted
/// into a pure function so it's unit-testable and readable top-to-bottom
/// instead of a ~70-line closure embedded in `GoRouter`'s constructor. Takes
/// the two async states it needs plus the current location, and returns
/// either a redirect path or `null` (stay put).
String? resolveAuthRedirect({
  required AsyncValue<User?> authState,
  required AsyncValue<AppUser?> profileState,
  required String location,
  required bool hasSeenWalkthrough,
}) {
  final isAuthRoute = _authRoutes.contains(location);

  // Firebase Auth hasn't reported an initial state yet — hold on the splash
  // screen rather than bouncing to /login prematurely.
  if (authState.isLoading && !authState.hasError) return null;

  final isLoggedIn = authState.value != null;
  if (!isLoggedIn) {
    return isAuthRoute ? null : RoutePaths.login;
  }

  // Logged in but the Firestore profile hasn't resolved yet — hold on the
  // current location. Right after a successful sign-in, `authState`
  // resolves before the profile's first snapshot arrives; treating that
  // transient null as "no profile" would flash even an active member
  // through /account-pending for a frame.
  if (profileState.isLoading && !profileState.hasError) return null;

  final profile = profileState.value;
  final isAdmin = profile?.role.canAccessAdminShell ?? false;
  final status = profile?.status ?? AccountStatus.noProfile;

  // There's no approval step to gate on here — a fresh registration or an
  // admin-provisioned account is immediately active. This only ever
  // triggers for a disabled account or a missing profile.
  if (status != AccountStatus.active) {
    return location == RoutePaths.accountPending
        ? null
        : RoutePaths.accountPending;
  }

  // An admin-provisioned account must set its own password before reaching
  // either shell (previously stored but never enforced).
  if (profile!.mustChangePassword) {
    return location == RoutePaths.forcedPasswordChange
        ? null
        : RoutePaths.forcedPasswordChange;
  }

  if (isAuthRoute ||
      location == RoutePaths.splash ||
      location == RoutePaths.accountPending ||
      location == RoutePaths.forcedPasswordChange) {
    if (!isAdmin && !hasSeenWalkthrough) return RoutePaths.memberWalkthrough;
    return isAdmin ? RoutePaths.adminDashboard : RoutePaths.home;
  }

  // A member who hasn't seen the walkthrough yet is held there until they
  // finish or skip it — matches the design intent of a short, mandatory-once
  // (but always skippable) tour rather than something easy to wander past.
  if (!isAdmin &&
      !hasSeenWalkthrough &&
      location != RoutePaths.memberWalkthrough) {
    return RoutePaths.memberWalkthrough;
  }

  if (!isAdmin && location.startsWith('/admin')) {
    return RoutePaths.home;
  }

  return null;
}
