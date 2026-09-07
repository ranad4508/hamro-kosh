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
  const FundRules({required this.monthlyContributionAmount});

  final double monthlyContributionAmount;

  static const defaults = FundRules(monthlyContributionAmount: 250);

  factory FundRules.fromFirestore(Map<String, dynamic> data) {
    return FundRules(
      monthlyContributionAmount:
          (data['monthlyContributionAmount'] as num?)?.toDouble() ??
          defaults.monthlyContributionAmount,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'monthlyContributionAmount': monthlyContributionAmount,
  };
}
