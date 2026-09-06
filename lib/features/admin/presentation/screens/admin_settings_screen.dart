import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/fund_rules.dart';
import '../../providers/admin_providers.dart';

/// SRS §39 — configurable contribution/loan/interest/repayment rules.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(fundRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (data) => _FundRulesForm(initial: data),
      ),
    );
  }
}

class _FundRulesForm extends ConsumerStatefulWidget {
  const _FundRulesForm({required this.initial});

  final FundRules initial;

  @override
  ConsumerState<_FundRulesForm> createState() => _FundRulesFormState();
}

class _FundRulesFormState extends ConsumerState<_FundRulesForm> {
  late final _monthly =
      TextEditingController(text: '${widget.initial.monthlyContributionAmount}');
  late final _interest =
      TextEditingController(text: '${widget.initial.defaultInterestRatePercent}');
  late final _months =
      TextEditingController(text: '${widget.initial.defaultRepaymentMonths}');
  late final _penalty = TextEditingController(text: '${widget.initial.latePenaltyPercent}');
  late final _grace = TextEditingController(text: '${widget.initial.gracePeriodDays}');
  late final _maxLoan = TextEditingController(text: '${widget.initial.maxLoanAmount}');
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(fundRulesRepositoryProvider).update(FundRules(
            monthlyContributionAmount: double.tryParse(_monthly.text) ?? widget.initial.monthlyContributionAmount,
            defaultInterestRatePercent: double.tryParse(_interest.text) ?? widget.initial.defaultInterestRatePercent,
            defaultRepaymentMonths: int.tryParse(_months.text) ?? widget.initial.defaultRepaymentMonths,
            latePenaltyPercent: double.tryParse(_penalty.text) ?? widget.initial.latePenaltyPercent,
            gracePeriodDays: int.tryParse(_grace.text) ?? widget.initial.gracePeriodDays,
            maxLoanAmount: double.tryParse(_maxLoan.text) ?? widget.initial.maxLoanAmount,
          ));
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          title: 'Settings saved',
          message: 'Fund rules have been updated.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not save',
          message: 'Something went wrong updating fund rules. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Contributions', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Monthly contribution amount (NPR)',
          controller: _monthly,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Loans & interest', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Default interest rate (% p.a.)',
          controller: _interest,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Default repayment period (months)',
          controller: _months,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Maximum loan amount (NPR)',
          controller: _maxLoan,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Late payments', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Late penalty (%)',
          controller: _penalty,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Grace period (days)',
          controller: _grace,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
      ],
    );
  }
}
