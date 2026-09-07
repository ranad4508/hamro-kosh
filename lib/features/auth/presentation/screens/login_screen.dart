import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/auth_form_controller.dart';
import '../widgets/auth_scaffold.dart';

/// The sign-in screen — no design mockup existed for this anywhere in the
/// 6-turn Nocturne design (`design_spec.md`'s headline finding: only a bare
/// "Already a member? Sign in" text link was drawn), so this is built fresh
/// in the same visual language (dark surfaces, bilingual labels, the shared
/// `AuthScaffold`/`AppTextField`/`AppButton` component set) rather than
/// left as a design gap.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authFormControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    // Successful sign-in is picked up by the router's authStateProvider
    // listener automatically; on failure the ref.listen below shows it.
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authFormControllerProvider, (previous, next) {
      if (next.hasError) {
        AppSnackbar.showError(
          context,
          title: 'Could not sign in',
          message: next.error.toString(),
        );
      }
    });
    final formState = ref.watch(authFormControllerProvider);

    return AuthScaffold(
      titleEn: 'Welcome back',
      titleNe: 'फेरि स्वागत छ',
      subtitleEn: 'Sign in to continue to your community fund.',
      subtitleNe: 'तपाईंको कोषमा जान साइन इन गर्नुहोस्।',
      children: [
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
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Password',
                controller: _password,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Password is required'
                    : null,
                autofillHints: const [AutofillHints.password],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(RoutePaths.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Sign in · साइन इन',
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
            const Text("New here?"),
            TextButton(
              onPressed: () => context.push(RoutePaths.register),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ],
    );
  }
}
