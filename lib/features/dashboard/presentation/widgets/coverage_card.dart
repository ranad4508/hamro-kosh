import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/month_grid_heatmap.dart';

/// "You are covered to [Month]" (`design_spec.md` §1a's home-screen card) —
/// the current-BS-year month grid plus a plain-language summary and a
/// direct "Give" shortcut, so a member sees whether they're caught up
/// without opening Give first.
class CoverageCard extends StatelessWidget {
  const CoverageCard({
    super.key,
    required this.coveredToLabel,
    required this.cells,
    required this.onGive,
  });

  final String? coveredToLabel;
  final List<({String label, MonthCellState state})> cells;
  final VoidCallback onGive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gaps = cells.where((c) => c.state == MonthCellState.gap).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coveredToLabel == null
                ? 'You have not given yet'
                : 'You are covered to $coveredToLabel',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          MonthGridHeatmap(cells: cells, columns: 6),
          const SizedBox(height: AppSpacing.sm),
          Text(
            gaps.isEmpty
                ? 'No gaps this year.'
                : '${gaps.map((g) => g.label).join(', ')} '
                      '${gaps.length == 1 ? 'is' : 'are'} still open.',
            style: TextStyle(fontSize: 11.5, color: colors.textQuaternary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Give to the fund', onPressed: onGive),
        ],
      ),
    );
  }
}
