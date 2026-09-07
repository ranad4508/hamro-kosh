import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../../loans/data/loan.dart';
import '../../../loans/providers/loans_providers.dart';
import '../../../members/providers/members_providers.dart';

/// `design_spec.md` §3b — the full-page loan review (LR-0042): the
/// borrower's record, what approving does to the fund, and the terms being
/// set, replacing the earlier bottom-sheet version which showed only the
/// category/amount/rate and a repayment-period picker.
class AdminLoanReviewScreen extends ConsumerStatefulWidget {
  const AdminLoanReviewScreen({super.key, required this.loanId});

  final String loanId;

  @override
  ConsumerState<AdminLoanReviewScreen> createState() =>
      _AdminLoanReviewScreenState();
}

class _AdminLoanReviewScreenState
    extends ConsumerState<AdminLoanReviewScreen> {
  final _reason = TextEditingController();
  int? _months;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reject(Loan loan) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(cloudFunctionsServiceProvider)
          .rejectLoan(loan.id, reason: _reason.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showInfo(
          context,
          title: 'Loan rejected',
          message: loan.borrowerName ?? loan.purpose,
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, title: 'Could not reject loan', message: e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(Loan loan) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(cloudFunctionsServiceProvider)
          .approveLoan(
            loanId: loan.id,
            repaymentMonths: _months,
            reason: _reason.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Loan approved',
          message: 'Repayment schedule set for ${loan.borrowerName ?? 'the borrower'}.',
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, title: 'Could not approve loan', message: e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanAsync = ref.watch(loanDetailProvider(widget.loanId));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Loan request')),
      body: loanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (loan) {
          if (loan == null) {
            return const EmptyState(icon: Icons.error_outline, title: 'Loan not found');
          }
          _months ??= loan.category.allowedRepaymentMonths.first;
          final allowedMonths = loan.category.allowedRepaymentMonths;
          final daysWaiting = DateTime.now().difference(loan.requestedAt).inDays;

          final memberAsync = loan.memberId == null
              ? null
              : ref.watch(memberDetailProvider(loan.memberId!));
          final allLoans = ref.watch(allLoansProvider(null)).value ?? const [];
          final priorLoans = loan.memberId == null
              ? 0
              : allLoans
                  .where(
                    (l) =>
                        l.memberId == loan.memberId &&
                        l.id != loan.id &&
                        l.requestedAt.isBefore(loan.requestedAt),
                  )
                  .length;

          final fundSummary = ref.watch(fundSummaryProvider);
          final inHandNow = fundSummary.value?.availableBalance;
          final inHandAfter = inHandNow == null ? null : inHandNow - loan.amount;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LR-${loan.id.substring(0, loan.id.length.clamp(0, 6)).toUpperCase()} · '
                          '$daysWaiting day${daysWaiting == 1 ? '' : 's'} waiting',
                          style: TextStyle(fontSize: 12, color: colors.textTertiary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.accent),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Review',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InitialsAvatar.fromName(loan.borrowerName ?? 'Member'),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.borrowerName ?? 'Member',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Text(
                                      memberAsync?.value?.memberSince == null
                                          ? (priorLoans == 0 ? 'Never borrowed' : '$priorLoans prior loan${priorLoans == 1 ? '' : 's'}')
                                          : 'Member since ${DateFormatter.monthYear(memberAsync!.value!.memberSince)} · '
                                                '${priorLoans == 0 ? 'never borrowed' : '$priorLoans prior loan${priorLoans == 1 ? '' : 's'}'}',
                                      style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: AppSpacing.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(loan.amount),
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'over ${allowedMonths.first} month${allowedMonths.first == 1 ? '' : 's'}',
                                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${loan.purpose}"',
                            style: TextStyle(fontStyle: FontStyle.italic, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('What approving does to the fund', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('In hand now', style: TextStyle(fontSize: 11, color: colors.textQuaternary)),
                                  Text(
                                    inHandNow == null ? '—' : CurrencyFormatter.format(inHandNow),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward, size: 18, color: colors.textQuaternary),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('In hand after', style: TextStyle(fontSize: 11, color: colors.textQuaternary)),
                                  Text(
                                    inHandAfter == null ? '—' : CurrencyFormatter.format(inHandAfter),
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.accentLight),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (inHandNow != null && inHandNow > 0)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (loan.amount / inHandNow).clamp(0, 1).toDouble(),
                                minHeight: 6,
                                backgroundColor: colors.surfaceSunken,
                                color: colors.accent,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'This loan is up to ${(loan.category.maxFundShare * 100).toStringAsFixed(0)}% of '
                            "the fund's available balance for its category — checked automatically at approval.",
                            style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Terms you are setting', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Material(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _TermRow('Amount approved', CurrencyFormatter.format(loan.amount)),
                          Divider(height: 1, color: colors.divider),
                          if (allowedMonths.length > 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Months', style: TextStyle(color: colors.textTertiary)),
                                  SegmentedButton<int>(
                                    segments: allowedMonths
                                        .map((m) => ButtonSegment(value: m, label: Text('$m')))
                                        .toList(),
                                    selected: {_months!},
                                    onSelectionChanged: (s) => setState(() => _months = s.first),
                                  ),
                                ],
                              ),
                            )
                          else
                            _TermRow('Months', '${allowedMonths.first}'),
                          Divider(height: 1, color: colors.divider),
                          _TermRow(
                            'Interest %/yr',
                            (loan.category.monthlyInterestRatePercent * 12).toStringAsFixed(0),
                          ),
                          Divider(height: 1, color: colors.divider),
                          const _TermRow('Method', 'Reducing'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Note for the audit trail',
                      controller: _reason,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "Needs a second admin's approval before the money moves. "
                      '${loan.borrowerName ?? 'The borrower'} sees these terms and must accept them.',
                      style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                    ),
                  ],
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _reject(loan),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Approve',
                        isLoading: _busy,
                        onPressed: () => _approve(loan),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.colors.textTertiary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
