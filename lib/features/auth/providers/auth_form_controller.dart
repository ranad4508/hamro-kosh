import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Drives the loading/error state for sign-in, registration, and password
/// reset submissions so screens just watch an [AsyncValue] instead of
/// managing `isLoading`/`errorText` booleans by hand.
class AuthFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
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

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    state = result;
    return !result.hasError;
  }
}

final authFormControllerProvider =
    AsyncNotifierProvider<AuthFormController, void>(AuthFormController.new);
