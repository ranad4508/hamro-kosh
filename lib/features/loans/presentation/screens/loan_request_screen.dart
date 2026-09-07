import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/rate_escalation_table.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../providers/loans_providers.dart';
import '../widgets/loan_cost_timeline.dart';

/// The loan-request wizard (`design_spec.md` §4c → §6a → §6b): three
/// sequential steps — category/amount, an on-time cost preview, then the
/// late-payment cost — rather than one long scrolling form, so a borrower
/// actually sees what the loan will cost before submitting rather than it
/// being buried further down a page they may not scroll to.
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
  int _step = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _purpose.dispose();
    super.dispose();
  }

  double get _amountValue => double.tryParse(_amount.text.trim()) ?? 0;

  void _goToCostStep() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  Future<void> _submit(int slotsAvailable) async {
    if (slotsAvailable <= 0) return;
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
            amount: _amountValue,
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
      body: SafeArea(
        child: Column(
          children: [
            switch (_step) {
              0 => AppHeader(
                titleEn: 'Request a loan',
                titleNe: 'ऋण अनुरोध',
                showBackButton: true,
                trailing: const Text('1 of 3'),
              ),
              1 => AppHeader(
                titleEn: 'What it will cost',
                titleNe: 'कति लाग्छ?',
                showBackButton: true,
                onBack: () => setState(() => _step = 0),
                trailing: const Text('2 of 3'),
              ),
              _ => AppHeader(
                titleEn: 'If the interest is late',
                titleNe: 'ब्याज ढिलो भएमा',
                showBackButton: true,
                onBack: () => setState(() => _step = 1),
                trailing: const Text('3 of 3'),
              ),
            },
            Expanded(
              child: switch (_step) {
                0 => _CategoryStep(
                  formKey: _formKey,
                  amount: _amount,
                  purpose: _purpose,
                  category: _category,
                  onCategoryChanged: (c) => setState(() => _category = c),
                  slotsAvailable: slotsAvailable,
                  categoryCap: categoryCap,
                  onContinue: _goToCostStep,
                ),
                1 => _CostStep(
                  principal: _amountValue,
                  category: _category,
                  onContinue: () => setState(() => _step = 2),
                ),
                _ => _LateCostStep(
                  principal: _amountValue,
                  category: _category,
                  submitting: _submitting,
                  onSubmit: slotsAvailable == null
                      ? null
                      : () => _submit(slotsAvailable),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    required this.formKey,
    required this.amount,
    required this.purpose,
    required this.category,
    required this.onCategoryChanged,
    required this.slotsAvailable,
    required this.categoryCap,
    required this.onContinue,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController amount;
  final TextEditingController purpose;
  final LoanCategory category;
  final ValueChanged<LoanCategory> onCategoryChanged;
  final int? slotsAvailable;
  final double? categoryCap;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          if (slotsAvailable != null)
            Card(
              color: slotsAvailable! > 0
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  slotsAvailable! > 0
                      ? '$slotsAvailable of $maxConcurrentLoans loan slots available fund-wide.'
                      : 'No loan slots available — $maxConcurrentLoans loans are already outstanding fund-wide.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text('Loan category', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<LoanCategory>(
            segments: LoanCategory.values
                .map((c) => ButtonSegment(value: c, label: Text(c.label)))
                .toList(),
            selected: {category},
            onSelectionChanged: (selection) =>
                onCategoryChanged(selection.first),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category.description +
                (categoryCap != null
                    ? ' Up to ${CurrencyFormatter.format(categoryCap!)} available for this category right now.'
                    : ''),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Requested amount (NPR)',
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: 'Rs. ',
            validator: (v) {
              final base = Validators.positiveAmount(v);
              if (base != null) return base;
              if (categoryCap != null && double.parse(v!.trim()) > categoryCap!) {
                return 'Exceeds the ${category.label.toLowerCase()} category cap of '
                    '${CurrencyFormatter.format(categoryCap!)}';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Purpose',
            controller: purpose,
            maxLines: 3,
            validator: (v) => Validators.required(v, field: 'Purpose'),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Continue with ${category.label}',
            onPressed: slotsAvailable == null || slotsAvailable! <= 0
                ? null
                : onContinue,
          ),
        ],
      ),
    );
  }
}

class _CostStep extends StatelessWidget {
  const _CostStep({
    required this.principal,
    required this.category,
    required this.onContinue,
  });

  final double principal;
  final LoanCategory category;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final due = category.allowedRepaymentMonths.first;
    final dueInterest =
        principal * category.monthlyInterestRatePercent / 100 * due;
    final dueTotal = principal + dueInterest;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(principal),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${category.label} · ${category.monthlyInterestRatePercent}% a month',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              BilingualText(
                'Interest as time passes',
                'समयअनुसार ब्याज',
                layout: BilingualLayout.inline,
                style: TextStyle(fontSize: 11, color: context.colors.accent),
              ),
              const SizedBox(height: AppSpacing.sm),
              LoanCostTimeline(principal: principal, category: category),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Interest is ${category.monthlyInterestRatePercent}% of the '
                '${CurrencyFormatter.format(principal)} every month — whether '
                'you deposit it monthly or at the end of the quarter.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due in $due month${due == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    CurrencyFormatter.format(dueTotal),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'See the late-payment cost',
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LateCostStep extends StatelessWidget {
  const _LateCostStep({
    required this.principal,
    required this.category,
    required this.submitting,
    required this.onSubmit,
  });

  final double principal;
  final LoanCategory category;
  final bool submitting;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.warningSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The penalty grows, it does not sit still',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Miss a payment date and $loanLatePenaltyMonthlyRatePercent% a '
                            'month is added on the whole ${CurrencyFormatter.format(principal)}, '
                            'counted from the day you got the money. Miss the next one and '
                            'another $loanLatePenaltyMonthlyRatePercent% is added on top.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'The same thing as your rule table',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              RateEscalationTable(principal: principal, category: category),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'How to avoid all of it',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _AvoidRow('Deposit on time every month or quarter.'),
              const _AvoidRow('Pay ahead when you can — it is never wasted.'),
              const _AvoidRow(
                'Tell the committee before a missed date — no penalty has '
                'ever been charged to someone who asked first.',
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: 'Submit request',
                isLoading: submitting,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvoidRow extends StatelessWidget {
  const _AvoidRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: context.colors.accentLight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
