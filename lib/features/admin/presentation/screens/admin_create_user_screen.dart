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

import '../../../members/data/member_directory_entry.dart';
import '../../../members/providers/members_providers.dart';

/// SRS.md §58 RBAC addition — an admin (or super admin) provisions a new
/// account directly, or edits an existing member's basic details.
class AdminCreateUserScreen extends ConsumerStatefulWidget {
  const AdminCreateUserScreen({super.key, this.member});

  final MemberDirectoryEntry? member;

  @override
  ConsumerState<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends ConsumerState<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _fullName = TextEditingController(text: widget.member?.fullName);
  late final _email = TextEditingController(text: widget.member?.email);
  late final _phone = TextEditingController(text: widget.member?.phone);
  late UserRole _role = widget.member?.role ?? UserRole.member;
  bool _submitting = false;

  bool get _isEditing => widget.member != null;

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
      final currentUid = ref.read(authStateProvider).value?.uid ?? '';
      
      if (_isEditing) {
        await ref.read(membersRepositoryProvider).updateMemberWithAudit(
          uid: widget.member!.uid,
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
          performedBy: currentUid,
        );
      } else {
        await ref
            .read(cloudFunctionsServiceProvider)
            .createUser(
              fullName: _fullName.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              role: _role.name,
            );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: _isEditing ? 'Member updated' : 'Account created',
          message: _isEditing
              ? 'Changes have been saved.'
              : '${_fullName.text.trim()} will receive their login details by email.',
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not save account',
          message: e.message,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Error',
          message: 'Something went wrong. Please try again.',
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit member' : 'Create account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!_isEditing)
              Text(
                'The new user will receive their login email and a temporary '
                'password by email, and will be asked to set their own '
                'password on first sign-in.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                'Update the member\'s basic contact details. Email cannot be changed.',
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
              enabled: !_isEditing,
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
            if (!_isEditing) ...[
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
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _isEditing ? 'Save changes' : 'Create account',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
