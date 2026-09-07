import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/bs_date_formatter.dart';

/// A single month cell's coverage state in a [MonthGridHeatmap].
enum MonthCellState {
  /// Already covered by a past, verified payment — dim purple.
  covered,

  /// Covered by the payment/selection currently being made — bright purple,
  /// the visually "hot" state.
  coveringNow,

  /// Due but not yet paid — a gap, shown as a dark inset box.
  gap,

  /// Not yet due (a future month) — plain, unmarked dark cell.
  future,
}

/// The month-coverage heatmap grid used on Home, Give, and My Record
/// (`design_spec.md` §2, pattern 6) — one cell per Nepali calendar month
/// (or a 24-cell 2-year variant on My Record), color-coded by
/// [MonthCellState] so a member can see at a glance which months they've
/// paid, which is being covered right now, and which are still open.
class MonthGridHeatmap extends StatelessWidget {
  const MonthGridHeatmap({
    super.key,
    required this.cells,
    this.columns = 4,
    this.showLegend = true,
  });

  /// One entry per month, in calendar order (Baisakh first). Each entry's
  /// label is typically a 3-letter BS month abbreviation
  /// ([BsDateFormatter.monthAbbreviations]).
  final List<({String label, MonthCellState state})> cells;
  final int columns;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) => _MonthCell(cell: cells[index]),
        ),
        if (showLegend) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: context.colors.accentDark3,
                label: 'Already covered',
              ),
              _LegendDot(color: context.colors.accent, label: 'This payment'),
              _LegendDot(
                color: context.colors.surfaceSunken,
                label: 'Not yet due',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.cell});

  final ({String label, MonthCellState state}) cell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color bg, Color fg, Border? border) = switch (cell.state) {
      MonthCellState.covered => (colors.accentDark3, colors.textPrimary, null),
      MonthCellState.coveringNow => (colors.accent, colors.bg, null),
      MonthCellState.gap => (
        colors.surfaceSunken,
        colors.textTertiary,
        Border.all(color: colors.accentDark1),
      ),
      MonthCellState.future => (
        colors.bg,
        colors.textQuaternary,
        Border.all(color: colors.neutralRing),
      ),
    };

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Text(
        cell.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: context.colors.textTertiary)),
      ],
    );
  }
}
