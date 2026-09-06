import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../providers/auth_form_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authFormControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());
    if (success) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authFormControllerProvider, (previous, next) {
      if (next.hasError) {
        AppSnackbar.showError(
          context,
          title: 'Could not send reset link',
          message: 'Check the email address and try again.',
        );
      }
    });
    final formState = ref.watch(authFormControllerProvider);

    return AuthScaffold(
      title: 'Reset password',
      subtitle:
          "Enter your email and we'll send you a link to reset your password.",
      children: [
        if (_sent)
          const Text(
            'If an account exists for that email, a reset link is on its way.',
          )
        else
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Send reset link',
                  isLoading: formState.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
