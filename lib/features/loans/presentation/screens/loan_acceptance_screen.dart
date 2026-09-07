import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/loan.dart';
import '../../providers/loans_providers.dart';

/// `design_spec.md` §2h — "Your loan terms": shown once a loan is approved,
/// so the borrower reads the actual numbers (what they'll receive, what
/// they'll pay back, and on what schedule) rather than only ever seeing
/// them buried inside the fuller Loan Detail screen. Note this app has no
/// separate disbursement gate — `approveLoan` (functions/index.js) disburses
/// the moment an admin approves it, so "accepting" here is an acknowledgment
/// of terms already in effect, not a trigger that moves money; the footer
/// copy is worded accordingly rather than copying the design's literal
/// "Accept and receive" (which would imply money moves on this tap).
class LoanAcceptanceScreen extends ConsumerWidget {
  const LoanAcceptanceScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = ref.watch(loanDetailProvider(loanId));

    return Scaffold(
      body: SafeArea(
        child: loan.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppErrorState(message: '$error'),
          data: (data) {
            if (data == null) {
              return const EmptyState(
                icon: Icons.error_outline,
                title: 'Loan not found',
              );
            }
            return _AcceptanceBody(loan: data);
          },
        ),
      ),
    );
  }
}

class _AcceptanceBody extends StatefulWidget {
  const _AcceptanceBody({required this.loan});
  final Loan loan;

  @override
  State<_AcceptanceBody> createState() => _AcceptanceBodyState();
}

class _AcceptanceBodyState extends State<_AcceptanceBody> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loan = widget.loan;
    final months = loan.repaymentMonths ?? 1;
    final totalPayable = loan.totalPayable ?? loan.amount;
    final interestPortion = totalPayable - loan.amount;
    final instalment = totalPayable / months;

    return Column(
      children: [
        AppHeader(
          titleEn: 'Your loan terms',
          titleNe: 'तपाईंको ऋणका सर्तहरू',
          showBackButton: true,
          trailing: Text(
            loan.disbursedAt == null
                ? 'Approved'
                : 'Approved ${DateFormatter.shortDate(loan.disbursedAt!)}',
            style: TextStyle(fontSize: 11.5, color: colors.textQuaternary),
          ),
        ),
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOU RECEIVED',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(loan.amount),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Divider(height: AppSpacing.lg),
                    Text(
                      'YOU WILL PAY BACK',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                        color: colors.textQuaternary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(totalPayable),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '${CurrencyFormatter.format(interestPortion)} of it interest',
                            style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'In $months monthly instalments of about '
                      '${CurrencyFormatter.format(instalment)}'
                      '${loan.nextDueDate == null ? '' : ', starting ${DateFormatter.shortDate(loan.nextDueDate!)}'}.',
                      style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _TermRow('Category', loan.category.label(context)),
                    _TermRow(
                      'Interest rate',
                      '${loan.interestRatePercent ?? loan.category.monthlyInterestRatePercent}%/mo, '
                          '${((loan.interestRatePercent ?? loan.category.monthlyInterestRatePercent) * 12).toStringAsFixed(0)}%/yr',
                    ),
                    const _TermRow('Calculated on', 'The principal'),
                    _TermRow('Repay by', 'End of $months month${months == 1 ? '' : 's'}'),
                    const _TermRow('Interest deposits', 'Monthly or quarterly'),
                    const _TermRow('Paying early', 'Allowed, no charge', isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.accentDark1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What the group agreed',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This loan comes out of money every member put in '
                      'together. Your name, the amount and your repayment '
                      'progress will be visible to every member in the '
                      'ledger. What you are borrowing for stays between you '
                      'and the committee.',
                      style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => context.push(RoutePaths.profileTerms),
                      child: Text(
                        'Read the full terms and conditions',
                        style: TextStyle(fontSize: 12.5, color: colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _acknowledged,
                onChanged: (v) => setState(() => _acknowledged = v ?? false),
                title: Text(
                  'I have read these terms and understand them. I will '
                  'repay ${CurrencyFormatter.format(totalPayable)} over '
                  '$months month${months == 1 ? '' : 's'}.',
                  style: const TextStyle(fontSize: 13),
                ),
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
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.neutralRing),
                  ),
                  child: const Text('Not now'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Got it, continue',
                  onPressed: _acknowledged
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow(this.label, this.value, {this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
