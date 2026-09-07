import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../providers/auth_form_controller.dart';
import '../widgets/auth_scaffold.dart';

/// The join/registration screen (`design_spec.md` §4a, minus the invite
/// code — there is no invite-code gate or approval step in this app): name,
/// mobile, email/password since the product decision was to keep
/// email/password auth rather than the design's undesigned phone/OTP
/// alternative — see design_spec.md's headline finding. Submits to
/// `registerMember` (via `AuthFormController`), which signs the member in
/// immediately — there's no pending state to wait on.
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
    if (ref.read(authFormControllerProvider).isLoading) return;
    await ref
        .read(authFormControllerProvider.notifier)
        .register(
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
    // No explicit navigation on success: registering also signs the member
    // in (see `AuthRepository.register`), and the router's redirect takes
    // it from there straight to Home — there's no approval step to wait on.
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authFormControllerProvider, (previous, next) {
      if (next.hasError) {
        AppSnackbar.showError(
          context,
          title: 'Could not create your account',
          message: next.error.toString(),
        );
      }
    });
    final formState = ref.watch(authFormControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return AuthScaffold(
      titleEn: 'Hamro Kosh',
      titleNe: 'हाम्रो कोष',
      subtitleEn:
          'A fund we build together, and anyone in it can see every rupee.',
      subtitleNe: 'हामीले सँगै बनाएको कोष, जसको हरेक रुपैयाँ सबैले देख्न सक्छ।',
      children: [
        BilingualText(
          'Choose your language',
          'भाषा',
          layout: BilingualLayout.inline,
          style: TextStyle(fontSize: 12, color: context.colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _LanguageCard(
                label: 'English',
                caption: 'Nepali shown below',
                selected: locale?.languageCode != 'ne',
                onTap: () => ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(const Locale('en')),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _LanguageCard(
                label: 'नेपाली',
                caption: 'English shown below',
                selected: locale?.languageCode == 'ne',
                onTap: () => ref
                    .read(localeControllerProvider.notifier)
                    .setLocale(const Locale('ne')),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name · पूरा नाम',
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
                label: 'Mobile number · मोबाइल नम्बर (+977)',
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
                label: 'Continue · जारी राख्नुहोस्',
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
            const Text('Already a member?'),
            TextButton(
              onPressed: () => context.go(RoutePaths.login),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.label,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? colors.accent : colors.neutralRing,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

