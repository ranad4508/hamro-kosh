import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';

/// SRS.md §58 RBAC addition — an admin (or super admin) provisions a new
/// account directly, skipping the self-registration approval queue. The
/// actual account creation + "here are your login credentials" email both
/// happen server-side, in the `createUserAccount` Cloud Function
/// (`functions/index.js`): a mobile client must never hold the ability to
/// mint Firebase Auth users with an arbitrary role, and must never construct
/// the credentials email itself (that requires the Resend API key, which
/// stays server-only).
class AdminCreateUserScreen extends ConsumerStatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  ConsumerState<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends ConsumerState<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  UserRole _role = UserRole.member;
  bool _submitting = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(cloudFunctionsServiceProvider)
          .createUser(
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            role: _role.name,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Account created',
          message:
              '${_fullName.text.trim()} will receive their login details by email.',
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not create account',
          message: e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreateAdmins = ref.watch(userRoleProvider).canCreateAdmins;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'The new user will receive their login email and a temporary '
              'password by email, and will be asked to set their own '
              'password on first sign-in.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Full name',
              controller: _fullName,
              prefixIcon: Icons.person_outline,
              validator: (v) => Validators.required(v, field: 'Full name'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Phone number',
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Role', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<UserRole>(
              segments: [
                const ButtonSegment(
                  value: UserRole.member,
                  label: Text('Member'),
                ),
                if (canCreateAdmins)
                  const ButtonSegment(
                    value: UserRole.admin,
                    label: Text('Admin'),
                  ),
              ],
              selected: {_role},
              onSelectionChanged: (selection) =>
                  setState(() => _role = selection.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Create account',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
