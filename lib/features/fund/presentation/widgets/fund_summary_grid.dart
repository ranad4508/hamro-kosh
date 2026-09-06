import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/finance_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/fund_summary.dart';

/// The metric grid backing SRS §6 (Fund Overview) and §54 (Core
/// Transparency Dashboard) — reused on both the member dashboard and the
/// admin dashboard.
class FundSummaryGrid extends StatelessWidget {
  const FundSummaryGrid({super.key, required this.summary});

  final FundSummary summary;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;

    final tiles = [
      (
        'Available balance',
        summary.availableBalance,
        Icons.account_balance_wallet,
        Theme.of(context).colorScheme.primary,
      ),
      ('Total contributed', summary.totalContributions, Icons.volunteer_activism, finance.income),
      ('Total loaned', summary.totalLoaned, Icons.call_made, finance.info),
      ('Outstanding loans', summary.outstandingLoans, Icons.hourglass_top, finance.pending),
      ('Total expenses', summary.totalExpenses, Icons.receipt_long, finance.expense),
      ('Interest earned', summary.interestEarned, Icons.percent, finance.income),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final (label, value, icon, color) = tiles[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: 40 * index),
          child: StatCard(
            label: label,
            value: CurrencyFormatter.formatCompact(value),
            icon: icon,
            accentColor: color,
          ),
        );
      },
    );
  }
}
