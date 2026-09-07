import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_category.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/loan_repayment.dart';
import '../../providers/loans_providers.dart';
import '../widgets/loan_cost_timeline.dart';

/// SRS §19, §20, §23 — loan terms, agreement summary, and repayment
/// schedule for a single loan.
class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = ref.watch(loanDetailProvider(loanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Loan details')),
      body: loan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Loan not found',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(data.amount),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  StatusBadge(label: data.status.label(context), tone: data.status.tone),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(data.purpose),
              if (data.status == LoanStatus.approved ||
                  data.status == LoanStatus.active) ...[
                const SizedBox(height: AppSpacing.md),
                _WhatTheGroupAgreedCard(loanId: loanId),
                const SizedBox(height: AppSpacing.sm),
                AppOutlinedButton(
                  label: 'Review your loan terms',
                  expand: true,
                  onPressed: () => context.push(RoutePaths.loanTerms(loanId)),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Loan terms'),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow('Category', data.category.label(context)),
              _InfoRow(
                'Requested on',
                DateFormatter.shortDate(data.requestedAt),
              ),
              _InfoRow(
                'Interest rate',
                data.interestRatePercent == null
                    ? '${data.category.monthlyInterestRatePercent}% / month (set at approval)'
                    : '${data.interestRatePercent}% / month',
              ),
              _InfoRow(
                'Repayment period',
                data.repaymentMonths == null
                    ? '—'
                    : '${data.repaymentMonths} months',
              ),
              _InfoRow(
                'Total payable',
                data.totalPayable == null
                    ? 'Set at approval'
                    : CurrencyFormatter.format(data.totalPayable!),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'If a repayment is late, a $loanLatePenaltyMonthlyRatePercent% monthly penalty is added '
                'to the principal from the disbursement date, escalating another '
                '$loanLatePenaltyMonthlyRatePercent% if the next payment is missed too.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'How the cost grows'),
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.repaymentMonths == null
                    ? 'Projected at this category\'s default terms — the actual due date is set on approval.'
                    : 'On time vs. what a missed payment adds, on this loan\'s own amount and rate.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              LoanCostTimeline(
                principal: data.amount,
                category: data.category,
                dueMonths: data.repaymentMonths,
              ),
              const SizedBox(height: AppSpacing.sm),
              const SectionHeader(title: 'Repayment progress'),
              const SizedBox(height: AppSpacing.sm),
              if (data.totalPayable != null) ...[
                LinearProgressIndicator(
                  value: (data.amountPaid / data.totalPayable!).clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _InfoRow(
                'Paid so far',
                CurrencyFormatter.format(data.amountPaid),
              ),
              _InfoRow(
                'Outstanding',
                CurrencyFormatter.format(data.outstanding),
              ),
              _InfoRow(
                'Next due date',
                data.nextDueDate == null
                    ? '—'
                    : DateFormatter.shortDate(data.nextDueDate!),
              ),
              if (data.countsTowardConcurrentCap) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Record a repayment',
                  onPressed: () => context.push(RoutePaths.loanRepay(loanId)),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Repayment history'),
              const SizedBox(height: AppSpacing.sm),
              Consumer(
                builder: (context, ref, _) {
                  final repayments = ref.watch(loanRepaymentsProvider(loanId));
                  return repayments.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => AppErrorState(message: '$error'),
                    data: (items) {
                      if (items.isEmpty) {
                        return const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No repayments recorded yet',
                        );
                      }
                      return Column(
                        children: [
                          for (final repayment in items)
                            _RepaymentTile(repayment: repayment),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The design's `2h` "what the group agreed" card — a loan is drawn from
/// money every member put in together, so its amount and repayment
/// progress are visible fund-wide (SRS §25/§54), while what it's actually
/// for stays between the borrower and the committee.
class _WhatTheGroupAgreedCard extends StatelessWidget {
  const _WhatTheGroupAgreedCard({required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentDark1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This loan comes out of money every member put in together. '
            'Your name, the amount, and your repayment progress are '
            'visible to every member in the ledger. What you are '
            'borrowing for stays between you and the committee.',
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
    );
  }
}

class _RepaymentTile extends StatelessWidget {
  const _RepaymentTile({required this.repayment});

  final LoanRepayment repayment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(CurrencyFormatter.format(repayment.amount)),
      subtitle: Text(
        repayment.status.name == 'verified' &&
                repayment.interestComponent != null
            ? '${DateFormatter.shortDate(repayment.date)} • principal '
                  '${CurrencyFormatter.format(repayment.principalComponent ?? 0)}, interest '
                  '${CurrencyFormatter.format(repayment.interestComponent ?? 0)}'
                  '${(repayment.penaltyComponent ?? 0) > 0 ? ', penalty ${CurrencyFormatter.format(repayment.penaltyComponent!)}' : ''}'
            : DateFormatter.shortDate(repayment.date),
      ),
      trailing: StatusBadge(
        label: repayment.status.label(context),
        tone: repayment.status.tone,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
