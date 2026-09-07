import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';

/// SRS §7/§8 — a contribution is either the recurring monthly amount or a
/// one-off special-occasion campaign (birthday, Dashain, Tihar, emergency,
/// community event, etc.).
enum ContributionCategory {
  monthly,
  special;

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      ContributionCategory.monthly => l10n.contributionCategoryMonthly,
      ContributionCategory.special => l10n.contributionCategorySpecial,
    };
  }
}
