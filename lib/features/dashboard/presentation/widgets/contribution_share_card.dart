import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

/// "Your part in it" (design's turn-1c home-screen concept, reused as a
/// supplementary Home widget) — a donut of the member's own share-of-months
/// paid since joining, next to the plain-language sentence the design
/// pairs it with.
class ContributionShareCard extends StatelessWidget {
  const ContributionShareCard({
    super.key,
    required this.sharePaid,
    required this.totalGiven,
    required this.gapNote,
  });

  final double sharePaid;
  final double totalGiven;

  /// e.g. "Asar is the one gap." — null once there are no gaps at all.
  final String? gapNote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = (sharePaid * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 28,
                    sections: [
                      PieChartSectionData(
                        value: sharePaid.clamp(0.001, 1),
                        color: colors.accent,
                        showTitle: false,
                        radius: 10,
                      ),
                      PieChartSectionData(
                        value: (1 - sharePaid).clamp(0.001, 1),
                        color: colors.surfaceSunken,
                        showTitle: false,
                        radius: 10,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your part in it',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                    children: [
                      const TextSpan(text: 'You have given '),
                      TextSpan(
                        text: CurrencyFormatter.format(totalGiven),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' — $percent% of the months since you joined.',
                      ),
                    ],
                  ),
                ),
                if (gapNote != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    gapNote!,
                    style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
