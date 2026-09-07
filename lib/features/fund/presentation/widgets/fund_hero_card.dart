import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/fund_summary.dart';

/// The fund's headline card (SRS §12/§13/§53/§54): "available cash",
/// "outstanding loans", and "total fund position" are three different
/// numbers, and a member should never mistake one for another. Rather than
/// three equal-weight tiles, this makes the relationship visually obvious —
/// a single segmented bar split between what's in hand and what's out on
/// loan, both summing to the total fund position shown underneath.
class FundHeroCard extends StatelessWidget {
  const FundHeroCard({super.key, required this.summary});

  final FundSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final inHand = summary.availableBalance;
    final lentOut = summary.outstandingLoans;
    final totalFundPosition = inHand + lentOut;
    final total = totalFundPosition <= 0 ? 1 : totalFundPosition;
    // Flex values, not fractions of the bar's pixel width directly — both
    // sides get at least 1 so `Expanded` always has something to lay out,
    // even when one side of the fund is currently empty.
    final inHandFlex = (inHand / total * 1000).round().clamp(1, 999);
    final lentOutFlex = 1000 - inHandFlex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available right now',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.format(inHand),
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 7,
                child: Row(
                  children: [
                    Expanded(
                      flex: inHandFlex,
                      child: Container(color: scheme.primary),
                    ),
                    Expanded(
                      flex: lentOutFlex,
                      child: Container(
                        color: lentOut > 0
                            ? scheme.tertiary
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: 4,
              children: [
                _Legend(
                  color: scheme.primary,
                  label: 'In hand ${CurrencyFormatter.format(inHand)}',
                ),
                _Legend(
                  color: scheme.tertiary,
                  label: 'Lent out ${CurrencyFormatter.format(lentOut)}',
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total fund position',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(totalFundPosition),
                  style: textTheme.titleSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
