import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';

/// Lets any member change their password — the completion of the RBAC
/// account-creation flow (SRS.md §58): an admin-created account signs in
/// with an emailed temporary password and sets its own here.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Password updated',
          message: 'Use your new password next time you sign in.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not change password',
          message: e.code == 'invalid-credential' || e.code == 'wrong-password'
              ? 'Your current password is incorrect.'
              : 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              label: 'Current password',
              controller: _currentPassword,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) =>
                  Validators.required(v, field: 'Current password'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'New password',
              controller: _newPassword,
              obscureText: true,
              prefixIcon: Icons.lock_reset_outlined,
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Confirm new password',
              controller: _confirmPassword,
              obscureText: true,
              prefixIcon: Icons.lock_reset_outlined,
              validator: (v) =>
                  Validators.confirmPassword(v, _newPassword.text),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Update password',
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
