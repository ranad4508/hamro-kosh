/// SRS §18, §39 — admin-configurable contribution rule. Stored as a single
/// `settings/fund_rules` document so both the member app (validating a
/// contribution amount, SRS §7) and the admin settings screen read the same
/// source of truth.
///
/// Loan interest/repayment/penalty terms are deliberately NOT here: SRS.md's
/// fixed lending policy (`LoanCategory` in `core/models/loan_category.dart`)
/// replaced the earlier admin-freeform rate, so those numbers are fixed in
/// code on both the client and in `functions/index.js`'s `approveLoan` —
/// not a per-fund setting. `AdminSettingsScreen` shows that fixed policy
/// read-only, sourced from `LoanCategory` directly, so it can never drift
/// out of sync with what's actually enforced.
class FundRules {
  const FundRules({
    required this.monthlyContributionAmount,
    required this.personalInterestRate,
    required this.emergencyInterestRate,
    required this.latePenaltyRate,
    required this.maxConcurrentLoans,
    required this.arrearsLimitMonths,
  });

  final double monthlyContributionAmount;
  final double personalInterestRate;
  final double emergencyInterestRate;
  final double latePenaltyRate;
  final int maxConcurrentLoans;
  final int arrearsLimitMonths;

  static const defaults = FundRules(
    monthlyContributionAmount: 250,
    personalInterestRate: 1.0,
    emergencyInterestRate: 0.5,
    latePenaltyRate: 1.5,
    maxConcurrentLoans: 2,
    arrearsLimitMonths: 6,
  );

  factory FundRules.fromFirestore(Map<String, dynamic> data) {
    double asDouble(String key, double fallback) =>
        (data[key] as num?)?.toDouble() ?? fallback;
    int asInt(String key, int fallback) =>
        (data[key] as num?)?.toInt() ?? fallback;

    return FundRules(
      monthlyContributionAmount:
          asDouble('monthlyContributionAmount', defaults.monthlyContributionAmount),
      personalInterestRate:
          asDouble('personalInterestRate', defaults.personalInterestRate),
      emergencyInterestRate:
          asDouble('emergencyInterestRate', defaults.emergencyInterestRate),
      latePenaltyRate:
          asDouble('latePenaltyRate', defaults.latePenaltyRate),
      maxConcurrentLoans:
          asInt('maxConcurrentLoans', defaults.maxConcurrentLoans),
      arrearsLimitMonths:
          asInt('arrearsLimitMonths', defaults.arrearsLimitMonths),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'monthlyContributionAmount': monthlyContributionAmount,
    'personalInterestRate': personalInterestRate,
    'emergencyInterestRate': emergencyInterestRate,
    'latePenaltyRate': latePenaltyRate,
    'maxConcurrentLoans': maxConcurrentLoans,
    'arrearsLimitMonths': arrearsLimitMonths,
  };
}
