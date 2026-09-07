/// SRS §46 — which non-critical email categories a member receives.
/// Critical financial notifications (e.g. account creation) can't be
/// disabled and aren't represented here; only the categories §46 explicitly
/// lists as toggleable are. Every field defaults to `true` so an account
/// with no `emailPreferences` field at all (every account created before
/// this feature existed) stays opted into everything it always got.
class EmailPreferences {
  const EmailPreferences({
    this.contributionConfirmations = true,
    this.loanUpdates = true,
    this.repaymentReminders = true,
    this.monthlyReports = true,
    this.communityAnnouncements = true,
  });

  final bool contributionConfirmations;
  final bool loanUpdates;
  final bool repaymentReminders;
  final bool monthlyReports;
  final bool communityAnnouncements;

  static const defaults = EmailPreferences();

  factory EmailPreferences.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    bool asBool(String key) => data[key] as bool? ?? true;
    return EmailPreferences(
      contributionConfirmations: asBool('contributionConfirmations'),
      loanUpdates: asBool('loanUpdates'),
      repaymentReminders: asBool('repaymentReminders'),
      monthlyReports: asBool('monthlyReports'),
      communityAnnouncements: asBool('communityAnnouncements'),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'contributionConfirmations': contributionConfirmations,
    'loanUpdates': loanUpdates,
    'repaymentReminders': repaymentReminders,
    'monthlyReports': monthlyReports,
    'communityAnnouncements': communityAnnouncements,
  };

  EmailPreferences copyWith({
    bool? contributionConfirmations,
    bool? loanUpdates,
    bool? repaymentReminders,
    bool? monthlyReports,
    bool? communityAnnouncements,
  }) {
    return EmailPreferences(
      contributionConfirmations:
          contributionConfirmations ?? this.contributionConfirmations,
      loanUpdates: loanUpdates ?? this.loanUpdates,
      repaymentReminders: repaymentReminders ?? this.repaymentReminders,
      monthlyReports: monthlyReports ?? this.monthlyReports,
      communityAnnouncements:
          communityAnnouncements ?? this.communityAnnouncements,
    );
  }
}
