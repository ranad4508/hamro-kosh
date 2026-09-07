import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic financial colors (income, expense, pending, informational) as a
/// [ThemeExtension] so screens never hardcode a raw hex for money-in/
/// money-out/overdue states. The Nocturne design is dark-only and reserves
/// color almost entirely for the purple accent ramp plus one warm terracotta
/// for danger/overdue — there is no green/red money-in/money-out convention
/// in the source design, so this intentionally does not invent one.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.pending,
    required this.info,
    required this.danger,
    required this.onIncomeContainer,
    required this.incomeContainer,
    required this.onExpenseContainer,
    required this.expenseContainer,
    required this.onDangerContainer,
    required this.dangerContainer,
  });

  /// Money coming in (contribution, repayment, interest) — the accent
  /// ramp's light step, used for "+delta" figures throughout the design.
  final Color income;

  /// Money going out (expense, loan disbursed) — kept as muted secondary
  /// text rather than a "negative" color; an outflow isn't a bad thing in
  /// this design's vocabulary, only overdue/penalty is.
  final Color expense;

  /// Awaiting verification/approval.
  final Color pending;

  /// Neutral informational tint (secondary accent).
  final Color info;

  /// Overdue, penalty, rejected, or otherwise needs-attention — the one
  /// warm terracotta reserved for danger states.
  final Color danger;

  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expenseContainer;
  final Color onExpenseContainer;
  final Color dangerContainer;
  final Color onDangerContainer;

  static final FinanceColors dark = FinanceColors(
    income: AppColors.dark.accentLight,
    expense: AppColors.dark.textSecondary,
    pending: AppColors.dark.accent,
    info: AppColors.dark.accent2,
    danger: AppColors.dark.warning,
    incomeContainer: AppColors.dark.accentDark2,
    onIncomeContainer: AppColors.dark.accentLightest,
    expenseContainer: AppColors.dark.surfaceSunken,
    onExpenseContainer: AppColors.dark.textSecondary,
    dangerContainer: AppColors.dark.warningSurface,
    onDangerContainer: AppColors.dark.warning,
  );

  static final FinanceColors light = FinanceColors(
    income: AppColors.light.accentLight,
    expense: AppColors.light.textSecondary,
    pending: AppColors.light.accent,
    info: AppColors.light.accent2,
    danger: AppColors.light.warning,
    incomeContainer: AppColors.light.accentDark2,
    onIncomeContainer: AppColors.light.accentLightest,
    expenseContainer: AppColors.light.surfaceSunken,
    onExpenseContainer: AppColors.light.textSecondary,
    dangerContainer: AppColors.light.warningSurface,
    onDangerContainer: AppColors.light.warning,
  );

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? pending,
    Color? info,
    Color? danger,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? expenseContainer,
    Color? onExpenseContainer,
    Color? dangerContainer,
    Color? onDangerContainer,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      pending: pending ?? this.pending,
      info: info ?? this.info,
      danger: danger ?? this.danger,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      onExpenseContainer: onExpenseContainer ?? this.onExpenseContainer,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      onIncomeContainer: Color.lerp(
        onIncomeContainer,
        other.onIncomeContainer,
        t,
      )!,
      expenseContainer: Color.lerp(
        expenseContainer,
        other.expenseContainer,
        t,
      )!,
      onExpenseContainer: Color.lerp(
        onExpenseContainer,
        other.onExpenseContainer,
        t,
      )!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(
        onDangerContainer,
        other.onDangerContainer,
        t,
      )!,
    );
  }
}

/// Convenience accessor: `context.financeColors.income`.
extension FinanceColorsX on BuildContext {
  FinanceColors get financeColors =>
      Theme.of(this).extension<FinanceColors>() ?? FinanceColors.dark;
}
