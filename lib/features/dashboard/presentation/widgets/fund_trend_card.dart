import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../fund/providers/fund_providers.dart';

/// "The fund over a year" (design's turn-1c home-screen concept, reused as
/// a supplementary Home widget per product decision rather than replacing
/// the balance-first layout) — a cumulative net-change line built from
/// [monthlyFundGrowthProvider]'s per-month income/expense, since the app
/// only stores the fund's *current* position, not a historical snapshot
/// per month. The Y axis is relative to the start of the window (0), not
/// an absolute balance, so the shape/direction of the trend is accurate
/// even though the line's starting height itself is arbitrary.
class FundTrendCard extends StatelessWidget {
  const FundTrendCard({super.key, required this.months});

  final List<MonthlyFundTotal> months;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (months.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    var running = 0.0;
    var dipMonth = months.first.month;
    var dipAmount = 0.0;
    for (var i = 0; i < months.length; i++) {
      final net = months[i].income - months[i].expense;
      if (net < dipAmount) {
        dipAmount = net;
        dipMonth = months[i].month;
      }
      running += net;
      spots.add(FlSpot(i.toDouble(), running));
    }
    final totalChange = running;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.15 + 1;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'The fund over a year',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${totalChange >= 0 ? '+' : ''}${CurrencyFormatter.formatCompact(totalChange)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: totalChange >= 0 ? colors.accentLight : colors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                minY: minY - pad,
                maxY: maxY + pad,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: colors.accent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.accent.withValues(alpha: 0.28),
                          colors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dipAmount < 0
                    ? '${DateFormatter.monthAbbr(dipMonth)} dipped the fund the most this year.'
                    : 'Steady growth all year — no month lost ground.',
                style: TextStyle(fontSize: 11, color: colors.textQuaternary),
              ),
              Text(
                'today',
                style: TextStyle(fontSize: 11, color: colors.textQuaternary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
