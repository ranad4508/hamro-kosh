import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';

/// SRS §17 — categories for a recorded community expense.
enum ExpenseCategory {
  birthday,
  dashain,
  tihar,
  emergency,
  communityEvent,
  memberSupport,
  gift,
  administration,
  other;

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      ExpenseCategory.birthday => l10n.expenseCategoryBirthday,
      ExpenseCategory.dashain => l10n.expenseCategoryDashain,
      ExpenseCategory.tihar => l10n.expenseCategoryTihar,
      ExpenseCategory.emergency => l10n.expenseCategoryEmergency,
      ExpenseCategory.communityEvent => l10n.expenseCategoryCommunityEvent,
      ExpenseCategory.memberSupport => l10n.expenseCategoryMemberSupport,
      ExpenseCategory.gift => l10n.expenseCategoryGift,
      ExpenseCategory.administration => l10n.expenseCategoryAdministration,
      ExpenseCategory.other => l10n.expenseCategoryOther,
    };
  }

  static ExpenseCategory fromName(String? name) => ExpenseCategory.values
      .firstWhere((c) => c.name == name, orElse: () => ExpenseCategory.other);
}
