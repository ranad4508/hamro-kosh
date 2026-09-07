import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../providers/auth_form_controller.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authFormControllerProvider.notifier)
        .register(
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
    if (success && mounted) {
      AppSnackbar.showSuccess(
        context,
        title: 'Account created',
        message:
            'Your account is awaiting admin approval before you can sign in.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authFormControllerProvider, (previous, next) {
      if (next.hasError) {
        AppSnackbar.showError(
          context,
          title: 'Registration failed',
          message: 'Could not create your account. Please try again.',
        );
      }
    });
    final formState = ref.watch(authFormControllerProvider);

    return AuthScaffold(
      title: 'Join your community fund',
      subtitle: 'Create an account to start contributing',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                controller: _fullName,
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.required(v, field: 'Full name'),
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: Validators.email,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Phone number',
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: Validators.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                controller: _password,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: Validators.password,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirm password',
                controller: _confirmPassword,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => Validators.confirmPassword(v, _password.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Create account',
                isLoading: formState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?'),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
