/// SRS §7/§8 — a contribution is either the recurring monthly amount or a
/// one-off special-occasion campaign (birthday, Dashain, Tihar, emergency,
/// community event, etc.).
enum ContributionCategory {
  monthly,
  special;

  String get label => switch (this) {
    ContributionCategory.monthly => 'Monthly',
    ContributionCategory.special => 'Special',
  };
}
