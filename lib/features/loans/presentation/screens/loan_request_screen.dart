import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_category.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../providers/loans_providers.dart';
import '../widgets/loan_cost_timeline.dart';

/// SRS §17-§19 — loan request form. There's no admin-chosen rate to pick:
/// the category (Personal/Emergency) fixes the interest rate, the fund-share
/// cap, and the repayment window, matching the fund's fixed lending policy.
class LoanRequestScreen extends ConsumerStatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  ConsumerState<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends ConsumerState<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _purpose = TextEditingController();
  LoanCategory _category = LoanCategory.personal;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _submit(int slotsAvailable) async {
    if (slotsAvailable <= 0) return;
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(loansRepositoryProvider)
          .requestLoan(
            uid: user.uid,
            memberName: profile?.fullName ?? user.email ?? 'Member',
            amount: double.parse(_amount.text.trim()),
            purpose: _purpose.text.trim(),
            category: _category,
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
          message:
              'Something went wrong sending your loan request. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(outstandingLoanCountProvider);
    final fundAsync = ref.watch(fundSummaryProvider);
    final slotsAvailable = switch (slotsAsync) {
      AsyncData(:final value) => maxConcurrentLoans - value,
      _ => null,
    };
    final availableBalance = switch (fundAsync) {
      AsyncData(:final value) => value.availableBalance,
      _ => null,
    };
    final categoryCap = availableBalance == null
        ? null
        : availableBalance * _category.maxFundShare;

    return Scaffold(
      appBar: AppBar(title: const Text('Request a loan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (slotsAvailable != null)
              Card(
                color: slotsAvailable > 0
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    slotsAvailable > 0
                        ? '$slotsAvailable of $maxConcurrentLoans loan slots available fund-wide.'
                        : 'No loan slots available — $maxConcurrentLoans loans are already outstanding fund-wide.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loan category',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<LoanCategory>(
              segments: LoanCategory.values
                  .map((c) => ButtonSegment(value: c, label: Text(c.label)))
                  .toList(),
              selected: {_category},
              onSelectionChanged: (selection) =>
                  setState(() => _category = selection.first),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _category.description +
                  (categoryCap != null
                      ? ' Up to ${CurrencyFormatter.format(categoryCap)} available for this category right now.'
                      : ''),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Requested amount (NPR)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Icons.currency_rupee,
              validator: (v) {
                final base = Validators.positiveAmount(v);
                if (base != null) return base;
                if (categoryCap != null &&
                    double.parse(v!.trim()) > categoryCap) {
                  return 'Exceeds the ${_category.label.toLowerCase()} category cap of '
                      '${CurrencyFormatter.format(categoryCap)}';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedBuilder(
              animation: _amount,
              builder: (context, _) {
                final amount = double.tryParse(_amount.text.trim()) ?? 0;
                if (amount <= 0) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What this will cost',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'On time vs. what a missed payment adds, at this amount and category.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LoanCostTimeline(principal: amount, category: _category),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                );
              },
            ),
            AppTextField(
              label: 'Purpose',
              controller: _purpose,
              maxLines: 3,
              validator: (v) => Validators.required(v, field: 'Purpose'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit request',
              isLoading: _submitting,
              onPressed: slotsAvailable == null
                  ? null
                  : () => _submit(slotsAvailable),
            ),
          ],
        ),
      ),
    );
  }
}
