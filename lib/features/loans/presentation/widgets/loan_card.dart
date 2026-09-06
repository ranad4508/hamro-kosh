import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/loan.dart';

/// Summary card for a loan — used in "My loans" and the admin loan list.
class LoanCard extends StatelessWidget {
  const LoanCard({super.key, required this.loan, this.onTap});

  final Loan loan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(loan.amount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  StatusBadge(label: loan.status.label, tone: loan.status.tone),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(loan.purpose, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (loan.totalPayable != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: (loan.amountPaid / loan.totalPayable!).clamp(0, 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Outstanding: ${CurrencyFormatter.format(loan.outstanding)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
