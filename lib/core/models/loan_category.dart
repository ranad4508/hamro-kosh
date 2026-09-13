import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

/// SRS §17-§19 — Hamro Kosh's fixed lending policy, taken from the
/// reference design. There is no admin-chosen interest rate: the category a
/// member requests under fixes the rate, the fund-share cap, and the
/// repayment window.
enum LoanCategory {
  personal,
  emergency;

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      LoanCategory.personal => l10n.loanCategoryPersonal,
      LoanCategory.emergency => l10n.loanCategoryEmergency,
    };
  }

  IconData get icon => switch (this) {
    LoanCategory.personal => Icons.person_outline,
    LoanCategory.emergency => Icons.emergency_outlined,
  };

  String get description => switch (this) {
    LoanCategory.personal =>
      'Up to 30% of the fund balance. Principal '
          'and interest are due within 1 quarter of disbursement.',
    LoanCategory.emergency =>
      'Up to 80% of the fund balance, for '
          'medical or accident emergencies. Due within 1-2 quarters of '
          'disbursement.',
  };

  /// Maximum share of the fund's available balance this category may
  /// disburse (checked server-side in `approveLoan` against `fund/summary`
  /// at approval time, since the balance moves between request and review).
  double get maxFundShare => switch (this) {
    LoanCategory.personal => 0.30,
    LoanCategory.emergency => 0.80,
  };

  /// Flat *monthly* interest rate (%) — total interest is this rate times
  /// the repayment months, not an annualized rate divided down.
  double get monthlyInterestRatePercent => switch (this) {
    LoanCategory.personal => 1.0,
    LoanCategory.emergency => 0.5,
  };

  /// Valid repayment windows in months (1 quarter = 3 months). Personal
  /// loans always repay within 1 quarter; emergency loans let the admin
  /// choose 1 or 2 quarters at approval time.
  List<int> get allowedRepaymentMonths => switch (this) {
    LoanCategory.personal => const [3],
    LoanCategory.emergency => const [3, 6],
  };

  static LoanCategory fromName(String? name) => LoanCategory.values.firstWhere(
    (c) => c.name == name,
    orElse: () => LoanCategory.personal,
  );
}

/// Penalty added on top of the category's monthly rate once a repayment is
/// late, escalating by the same amount again if the following payment is
/// missed too (SRS §21 + the reference design's late-payment terms).
const double loanLatePenaltyMonthlyRatePercent = 1.5;

/// At most this many loans may be outstanding (approved and not yet fully
/// repaid) across the whole fund at once — a fund-wide cap, not per member.
const int maxConcurrentLoans = 2;

/// Interest owed if [elapsedMonths] have passed since disbursement — mirrors
/// `interestOwedAt` in functions/index.js exactly (same formula, same
/// constants), so a client-computed "what's owed right now" figure never
/// drifts from what `verifyRepayment` will actually charge. Past the due
/// date, every additional full repayment cycle that goes unpaid adds another
/// [loanLatePenaltyMonthlyRatePercent] to the rate applied over the whole
/// elapsed period (SRS §21).
double loanInterestOwedAt({
  required double principal,
  required double monthlyRatePercent,
  required int dueMonths,
  required double elapsedMonths,
}) {
  final months = elapsedMonths < 0 ? 0.0 : elapsedMonths;
  if (months <= dueMonths) {
    return principal * monthlyRatePercent / 100 * months;
  }
  final missedCycles = ((months - dueMonths) / dueMonths).ceil();
  final effectiveRate =
      monthlyRatePercent + missedCycles * loanLatePenaltyMonthlyRatePercent;
  return principal * effectiveRate / 100 * months;
}
