import 'package:flutter/material.dart';

import '../models/loan_status.dart';
import '../theme/finance_colors.dart';

/// A small colored pill showing a loan/contribution/transaction status,
/// resolved against [FinanceColors] + [ColorScheme] so it looks correct in
/// both themes without any screen picking raw colors itself.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final scheme = Theme.of(context).colorScheme;

    final (Color fg, Color bg) = switch (tone) {
      StatusTone.positive => (
        finance.onIncomeContainer,
        finance.incomeContainer,
      ),
      StatusTone.negative => (
        finance.onExpenseContainer,
        finance.expenseContainer,
      ),
      StatusTone.pending => (
        scheme.onSurface,
        finance.pending.withValues(alpha: 0.22),
      ),
      StatusTone.info => (
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
      StatusTone.neutral => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
