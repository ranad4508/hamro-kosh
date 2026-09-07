import 'package:flutter/material.dart';

/// Semantic financial colors (income, expense, pending, informational) as a
/// [ThemeExtension] so screens never hardcode `Colors.green`/`Colors.red`
/// for money-in/money-out states — the same call always resolves correctly
/// in both light and dark mode.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.pending,
    required this.info,
    required this.onIncomeContainer,
    required this.incomeContainer,
    required this.onExpenseContainer,
    required this.expenseContainer,
  });

  final Color income;
  final Color expense;
  final Color pending;
  final Color info;
  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expenseContainer;
  final Color onExpenseContainer;

  static const FinanceColors light = FinanceColors(
    income: Color(0xFF1B8A5A),
    expense: Color(0xFFC22B2B),
    pending: Color(0xFFB8790A),
    info: Color(0xFF2563EB),
    incomeContainer: Color(0xFFDCF5E7),
    onIncomeContainer: Color(0xFF07331E),
    expenseContainer: Color(0xFFFBE2E2),
    onExpenseContainer: Color(0xFF460E0E),
  );

  static const FinanceColors dark = FinanceColors(
    income: Color(0xFF6FDBA0),
    expense: Color(0xFFF29B9B),
    pending: Color(0xFFF2C069),
    info: Color(0xFF93B7FF),
    incomeContainer: Color(0xFF0E3423),
    onIncomeContainer: Color(0xFFC5F3D8),
    expenseContainer: Color(0xFF4A1414),
    onExpenseContainer: Color(0xFFFAD3D3),
  );

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? pending,
    Color? info,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? expenseContainer,
    Color? onExpenseContainer,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      pending: pending ?? this.pending,
      info: info ?? this.info,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      onExpenseContainer: onExpenseContainer ?? this.onExpenseContainer,
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
    );
  }
}

/// Convenience accessor: `context.financeColors.income`.
extension FinanceColorsX on BuildContext {
  FinanceColors get financeColors =>
      Theme.of(this).extension<FinanceColors>() ?? FinanceColors.light;
}
