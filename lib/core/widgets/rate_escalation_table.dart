import 'package:flutter/material.dart';

import '../models/loan_category.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// The design's div-grid penalty table (`design_spec.md` §2, pattern 8;
/// screens `6b`/`4c`): Time / Rate / Total% / Interest, computed from the
/// same rule-16 formula `LoanCostTimeline` charts as bars — this is the
/// literal-numbers view of the same math, reused wherever a member needs to
/// see "the same thing as your rule table."
///
/// Milestones are fixed at 3/6/9/12/15/18 months, matching the exact
/// worked example the design (and the fund's real bylaws) uses.
class RateEscalationTable extends StatelessWidget {
  const RateEscalationTable({
    super.key,
    required this.principal,
    required this.category,
    this.dueMonths,
  });

  final double principal;
  final LoanCategory category;
  final int? dueMonths;

  int get _due => dueMonths ?? category.allowedRepaymentMonths.first;

  static const _milestones = [3, 6, 9, 12, 15, 18];

  @override
  Widget build(BuildContext context) {
    final due = _due;
    final baseAnnualPercent = category.monthlyInterestRatePercent * 12;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceSunken,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _row(
            context,
            time: 'Time',
            rate: 'Rate',
            total: 'Total',
            interest: 'Interest',
            isHeader: true,
          ),
          for (final months in _milestones)
            _dataRow(context, months, due, baseAnnualPercent),
        ],
      ),
    );
  }

  Widget _dataRow(
    BuildContext context,
    int months,
    int due,
    double baseAnnualPercent,
  ) {
    final missedCycles = months <= due ? 0 : ((months - due) / due).ceil();
    final effectiveMonthlyRate =
        category.monthlyInterestRatePercent +
        missedCycles * loanLatePenaltyMonthlyRatePercent;
    final totalPercent = effectiveMonthlyRate * months;
    final interest = loanInterestOwedAt(
      principal: principal,
      monthlyRatePercent: category.monthlyInterestRatePercent,
      dueMonths: due,
      elapsedMonths: months.toDouble(),
    );
    final isDanger = missedCycles > 0;

    final rateLabel = missedCycles == 0
        ? '${baseAnnualPercent.toStringAsFixed(0)}%'
        : '${baseAnnualPercent.toStringAsFixed(0)}% + '
              '${(missedCycles * loanLatePenaltyMonthlyRatePercent * 12).toStringAsFixed(0)}%';

    return _row(
      context,
      time: '$months mo',
      rate: rateLabel,
      total: '${totalPercent.toStringAsFixed(0)}%',
      interest: CurrencyFormatter.format(interest),
      isDanger: isDanger,
    );
  }

  Widget _row(
    BuildContext context, {
    required String time,
    required String rate,
    required String total,
    required String interest,
    bool isHeader = false,
    bool isDanger = false,
  }) {
    final colors = context.colors;
    final color = isHeader
        ? colors.textTertiary
        : isDanger
        ? colors.warning
        : colors.textPrimary;
    final style = TextStyle(
      fontSize: isHeader ? 10.5 : 12.5,
      fontWeight: isHeader ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: isHeader ? 0.4 : 0,
      color: color,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rowDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: Text(
              isHeader ? time.toUpperCase() : time,
              style: style,
            ),
          ),
          Expanded(flex: 14, child: Text(rate, style: style)),
          Expanded(flex: 9, child: Text(total, style: style)),
          Expanded(
            flex: 10,
            child: Text(interest, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
