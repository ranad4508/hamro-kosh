import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/loans_providers.dart';

/// SRS §15 — loan request form (amount, purpose, preferred duration).
class LoanRequestScreen extends ConsumerStatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  ConsumerState<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends ConsumerState<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _purpose = TextEditingController();
  int _months = 6;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(loansRepositoryProvider).requestLoan(
            uid: user.uid,
            memberName: profile?.fullName ?? user.email ?? 'Member',
            amount: double.parse(_amount.text.trim()),
            purpose: _purpose.text.trim(),
            preferredMonths: _months,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Request submitted',
          message: 'Your loan request has been sent for admin review.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not submit',
          message: 'Something went wrong sending your loan request. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request a loan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              label: 'Requested amount (NPR)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveAmount,
              prefixIcon: Icons.currency_rupee,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Purpose',
              controller: _purpose,
              maxLines: 3,
              validator: (v) => Validators.required(v, field: 'Purpose'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Preferred repayment duration', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [3, 6, 12, 24].map((months) {
                return ChoiceChip(
                  label: Text('$months months'),
                  selected: _months == months,
                  onSelected: (_) => setState(() => _months = months),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit request',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
