/// SRS §29 — admin-configurable visibility of certain member-to-member
/// financial/personal details. Deliberately a short list: only fields the
/// app actually displays to *other* members are toggleable here. Fund
/// expenses (recipient, category, amount) are NOT included — SRS frames
/// transparency as the default and privacy as the exception for personally
/// sensitive information; a recorded community expense is fund governance,
/// not personal privacy, so it stays always-visible in the ledger (same
/// principle contributions/loans already follow). Email similarly stays
/// admin/self-only always — there's no member-directory feature exposing
/// another member's email today, and adding one isn't part of this toggle.
class PrivacySettings {
  const PrivacySettings({
    required this.showContributionAmounts,
    required this.showActiveLoanStatus,
    required this.showPhoneNumber,
  });

  /// Member Detail's "Total contributed" figure, visible to other members.
  final bool showContributionAmounts;

  /// Member Detail's "Active loan: Yes/None" row and the directory's
  /// outstanding-loan indicator icon.
  final bool showActiveLoanStatus;

  /// Member Detail's phone number row.
  final bool showPhoneNumber;

  static const defaults = PrivacySettings(
    showContributionAmounts: true,
    showActiveLoanStatus: true,
    showPhoneNumber: false,
  );

  factory PrivacySettings.fromFirestore(Map<String, dynamic> data) {
    return PrivacySettings(
      showContributionAmounts:
          data['showContributionAmounts'] as bool? ??
          defaults.showContributionAmounts,
      showActiveLoanStatus:
          data['showActiveLoanStatus'] as bool? ??
          defaults.showActiveLoanStatus,
      showPhoneNumber:
          data['showPhoneNumber'] as bool? ?? defaults.showPhoneNumber,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'showContributionAmounts': showContributionAmounts,
    'showActiveLoanStatus': showActiveLoanStatus,
    'showPhoneNumber': showPhoneNumber,
  };

  PrivacySettings copyWith({
    bool? showContributionAmounts,
    bool? showActiveLoanStatus,
    bool? showPhoneNumber,
  }) {
    return PrivacySettings(
      showContributionAmounts:
          showContributionAmounts ?? this.showContributionAmounts,
      showActiveLoanStatus: showActiveLoanStatus ?? this.showActiveLoanStatus,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
    );
  }
}
