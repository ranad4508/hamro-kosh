import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/auth_form_controller.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

/// Shown when `AppUser.mustChangePassword` is true — an admin-provisioned
/// account (`createUserAccount` in functions/index.js) is created with a
/// system-generated temporary password and this flag set, but nothing in
/// the router previously enforced it: a user could sign in with the temp
/// password indefinitely without ever setting their own. The router's
/// `resolveAuthRedirect` now routes here before either shell whenever the
/// flag is set, so this is no longer just a stored-but-unused field.
class ForcedPasswordChangeScreen extends ConsumerStatefulWidget {
  const ForcedPasswordChangeScreen({super.key});

  @override
  ConsumerState<ForcedPasswordChangeScreen> createState() =>
      _ForcedPasswordChangeScreenState();
}

class _ForcedPasswordChangeScreenState
    extends ConsumerState<ForcedPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (ref.read(authFormControllerProvider).isLoading) return;
    await ref
        .read(authFormControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
    // Success clears `mustChangePassword` server-side; the router's
    // redirect picks up the profile change and moves on automatically.
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authFormControllerProvider, (previous, next) {
      if (next.hasError) {
        AppSnackbar.showError(
          context,
          title: 'Could not update your password',
          message: next.error.toString(),
        );
      }
    });
    final formState = ref.watch(authFormControllerProvider);

    return AuthScaffold(
      titleEn: 'Set your own password',
      titleNe: 'आफ्नो पासवर्ड सेट गर्नुहोस्',
      subtitleEn:
          'An administrator created this account with a temporary password. '
          'Choose your own before continuing.',
      subtitleNe: 'प्रशासकले अस्थायी पासवर्डसहित यो खाता बनाउनुभयो — जारी राख्नु अघि आफ्नै पासवर्ड सेट गर्नुहोस्।',
      showLogo: false,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Temporary password (from your email)',
                controller: _currentPassword,
                obscureText: true,
                prefixIcon: Icons.mail_lock_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'New password',
                controller: _newPassword,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: Validators.password,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirm new password',
                controller: _confirmPassword,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => Validators.confirmPassword(v, _newPassword.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Set password and continue',
                isLoading: formState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppGhostButton(
                label: 'Sign out',
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
