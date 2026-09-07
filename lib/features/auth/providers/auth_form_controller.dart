import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Wraps sign-in/register/password-reset/change-password calls in
/// [AsyncValue.guard] so screens get a consistent `isLoading`/`hasError`
/// to watch, with the *actual* [AuthFailure] preserved in the error state —
/// screens read `error.toString()` for a specific message rather than a
/// hardcoded generic string.
class AuthFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> signIn(String email, String password) {
    return _run(
      () => ref.read(authRepositoryProvider).signIn(email, password),
    );
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .register(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password,
          ),
    );
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          ),
    );
  }
}

final authFormControllerProvider =
    AsyncNotifierProvider<AuthFormController, void>(AuthFormController.new);
