import 'package:flutter/material.dart';

import '../../../../core/models/loan_category.dart';
import '../../../../core/utils/currency_formatter.dart';

/// A milestone-by-milestone view of how much interest a loan accrues over
/// time, growing a bar rather than just stating a number — so a borrower
/// (or a member still filling out the request form) can feel what the late
/// penalty actually costs, not just read a percentage (SRS §19/§21).
///
/// Pass [dueMonths] for a real, approved loan (its own repayment window);
/// leave it null while previewing a not-yet-submitted request, in which
/// case the category's own default window is used and the last milestone
/// illustrates what happens if a payment is missed.
class LoanCostTimeline extends StatelessWidget {
  const LoanCostTimeline({
    super.key,
    required this.principal,
    required this.category,
    this.dueMonths,
  });

  final double principal;
  final LoanCategory category;
  final int? dueMonths;

  int get _due => dueMonths ?? category.allowedRepaymentMonths.first;

  /// Interest owed if `months` have elapsed since disbursement. Past the
  /// due date, every additional full repayment cycle that goes unpaid adds
  /// another `loanLatePenaltyMonthlyRatePercent` to the rate applied over
  /// the whole elapsed period — "miss a payment date... miss the next one
  /// and another 1.5% is added on top" (SRS §21).
  double _interestAt(int months) {
    if (months <= _due) {
      return principal * category.monthlyInterestRatePercent / 100 * months;
    }
    final missedCycles = ((months - _due) / _due).ceil();
    final effectiveRate =
        category.monthlyInterestRatePercent +
        missedCycles * loanLatePenaltyMonthlyRatePercent;
    return principal * effectiveRate / 100 * months;
  }

  @override
  Widget build(BuildContext context) {
    if (principal <= 0) return const SizedBox.shrink();

    final due = _due;
    final milestones = {due, due * 2, due * 4}.toList()..sort();
    final values = {for (final m in milestones) m: _interestAt(m)};
    final maxValue = [
      principal,
      ...values.values,
    ].reduce((a, b) => a > b ? a : b);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final principalFraction = (principal / maxValue).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final lineX = (constraints.maxWidth * principalFraction).clamp(
          0.0,
          constraints.maxWidth,
        );
        return Stack(
          children: [
            Positioned(
              left: lineX,
              top: 0,
              bottom: 20,
              child: Container(width: 1, color: scheme.outlineVariant),
            ),
            Positioned(
              left: (lineX - 70).clamp(
                0.0,
                (constraints.maxWidth - 140).clamp(0.0, double.infinity),
              ),
              bottom: 0,
              width: 140,
              child: Text(
                '= the ${CurrencyFormatter.format(principal)} borrowed',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 26, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: values.entries.map((entry) {
                  final months = entry.key;
                  final interest = entry.value;
                  final isOverdue = months > due;
                  final fraction = (interest / maxValue).clamp(0.0, 1.0);
                  final label = months == due
                      ? '$months months · due'
                      : '$months months · overdue';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label, style: textTheme.bodySmall),
                            Text(
                              CurrencyFormatter.format(interest),
                              style: textTheme.bodySmall?.copyWith(
                                color: isOverdue
                                    ? scheme.error
                                    : scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 11,
                            backgroundColor: scheme.surfaceContainerHighest,
                            color: isOverdue ? scheme.error : scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
