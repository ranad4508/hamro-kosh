/// Aggregated fund totals for the transparency dashboard (SRS §5, §6, §54).
/// In production this is written by a Cloud Function whenever a transaction
/// is recorded, so clients only ever read one cheap document instead of
/// summing the whole ledger on-device.
class FundSummary {
  const FundSummary({
    required this.availableBalance,
    required this.totalContributions,
    required this.totalSpecialContributions,
    required this.totalExpenses,
    required this.totalLoaned,
    required this.outstandingLoans,
    required this.interestEarned,
    required this.otherIncome,
  });

  final double availableBalance;
  final double totalContributions;
  final double totalSpecialContributions;
  final double totalExpenses;
  final double totalLoaned;
  final double outstandingLoans;
  final double interestEarned;
  final double otherIncome;

  /// SRS §6 fund formula: Available = Income − Expenses − Outstanding/Lent.
  double get totalIncome =>
      totalContributions +
      totalSpecialContributions +
      interestEarned +
      otherIncome;

  static const zero = FundSummary(
    availableBalance: 0,
    totalContributions: 0,
    totalSpecialContributions: 0,
    totalExpenses: 0,
    totalLoaned: 0,
    outstandingLoans: 0,
    interestEarned: 0,
    otherIncome: 0,
  );

  factory FundSummary.fromFirestore(Map<String, dynamic> data) {
    double asDouble(String key) => (data[key] as num?)?.toDouble() ?? 0;
    return FundSummary(
      availableBalance: asDouble('availableBalance'),
      totalContributions: asDouble('totalContributions'),
      totalSpecialContributions: asDouble('totalSpecialContributions'),
      totalExpenses: asDouble('totalExpenses'),
      totalLoaned: asDouble('totalLoaned'),
      outstandingLoans: asDouble('outstandingLoans'),
      interestEarned: asDouble('interestEarned'),
      otherIncome: asDouble('otherIncome'),
    );
  }
}
