/// SRS §18, §39 — admin-configurable contribution/loan/interest rules.
/// Stored as a single `settings/fund_rules` document so both the member
/// app (to show borrowers the rule before they accept a loan, SRS §19) and
/// the admin settings screen read the same source of truth.
class FundRules {
  const FundRules({
    required this.monthlyContributionAmount,
    required this.defaultInterestRatePercent,
    required this.defaultRepaymentMonths,
    required this.latePenaltyPercent,
    required this.gracePeriodDays,
    required this.maxLoanAmount,
  });

  final double monthlyContributionAmount;
  final double defaultInterestRatePercent;
  final int defaultRepaymentMonths;
  final double latePenaltyPercent;
  final int gracePeriodDays;
  final double maxLoanAmount;

  static const defaults = FundRules(
    monthlyContributionAmount: 200,
    defaultInterestRatePercent: 12,
    defaultRepaymentMonths: 6,
    latePenaltyPercent: 2,
    gracePeriodDays: 7,
    maxLoanAmount: 50000,
  );

  factory FundRules.fromFirestore(Map<String, dynamic> data) {
    double asDouble(String key, double fallback) =>
        (data[key] as num?)?.toDouble() ?? fallback;
    int asInt(String key, int fallback) => (data[key] as num?)?.toInt() ?? fallback;

    return FundRules(
      monthlyContributionAmount:
          asDouble('monthlyContributionAmount', defaults.monthlyContributionAmount),
      defaultInterestRatePercent:
          asDouble('defaultInterestRatePercent', defaults.defaultInterestRatePercent),
      defaultRepaymentMonths:
          asInt('defaultRepaymentMonths', defaults.defaultRepaymentMonths),
      latePenaltyPercent: asDouble('latePenaltyPercent', defaults.latePenaltyPercent),
      gracePeriodDays: asInt('gracePeriodDays', defaults.gracePeriodDays),
      maxLoanAmount: asDouble('maxLoanAmount', defaults.maxLoanAmount),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'monthlyContributionAmount': monthlyContributionAmount,
        'defaultInterestRatePercent': defaultInterestRatePercent,
        'defaultRepaymentMonths': defaultRepaymentMonths,
        'latePenaltyPercent': latePenaltyPercent,
        'gracePeriodDays': gracePeriodDays,
        'maxLoanAmount': maxLoanAmount,
      };
}
