import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_category.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/fund_rules.dart';
import '../../providers/admin_providers.dart';

/// SRS §39 — the fund's configurable contribution rule, plus the fixed
/// lending policy shown read-only for reference (it isn't a setting — see
/// `FundRules`'s doc comment for why).
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
  late final _monthly = TextEditingController(
    text: '${widget.initial.monthlyContributionAmount}',
  );
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(fundRulesRepositoryProvider)
          .update(
            FundRules(
              monthlyContributionAmount:
                  double.tryParse(_monthly.text) ??
                  widget.initial.monthlyContributionAmount,
            ),
          );
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
          message:
              'Something went wrong updating fund rules. Please try again.',
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
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
        const SizedBox(height: AppSpacing.xl),
        Text('Lending policy', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Fixed in the app and Cloud Functions — not a setting here, so a "
          "member's loan terms always match what's actually enforced when "
          "it's approved.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final category in LoanCategory.values) ...[
          Card(
            child: ListTile(
              leading: Icon(category.icon),
              title: Text(category.label),
              subtitle: Text(category.description),
              trailing: Text(
                '${category.monthlyInterestRatePercent}%/mo',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Card(
          child: ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Late-payment penalty'),
            subtitle: Text(
              'Escalates by $loanLatePenaltyMonthlyRatePercent%/mo on the principal '
              'for every repayment cycle missed after the due date.',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Card(
          child: ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Maximum concurrent loans'),
            trailing: Text(
              '$maxConcurrentLoans',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
      ],
    );
  }
}
