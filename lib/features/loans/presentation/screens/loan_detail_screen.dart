import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../providers/loans_providers.dart';

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
            return const EmptyState(icon: Icons.error_outline, title: 'Loan not found');
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
                  StatusBadge(label: data.status.label, tone: data.status.tone),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(data.purpose),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Loan terms'),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow('Requested on', DateFormatter.shortDate(data.requestedAt)),
              _InfoRow(
                'Interest rate',
                data.interestRatePercent == null
                    ? 'Set at approval'
                    : '${data.interestRatePercent}% p.a.',
              ),
              _InfoRow(
                'Repayment period',
                data.repaymentMonths == null ? '—' : '${data.repaymentMonths} months',
              ),
              _InfoRow(
                'Total payable',
                data.totalPayable == null
                    ? 'Set at approval'
                    : CurrencyFormatter.format(data.totalPayable!),
              ),
              const SizedBox(height: AppSpacing.lg),
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
              _InfoRow('Paid so far', CurrencyFormatter.format(data.amountPaid)),
              _InfoRow('Outstanding', CurrencyFormatter.format(data.outstanding)),
              _InfoRow(
                'Next due date',
                data.nextDueDate == null ? '—' : DateFormatter.shortDate(data.nextDueDate!),
              ),
            ],
          );
        },
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
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
