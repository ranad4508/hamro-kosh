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

  String get label => switch (this) {
    ExpenseCategory.birthday => 'Birthday',
    ExpenseCategory.dashain => 'Dashain',
    ExpenseCategory.tihar => 'Tihar',
    ExpenseCategory.emergency => 'Emergency',
    ExpenseCategory.communityEvent => 'Community event',
    ExpenseCategory.memberSupport => 'Member support',
    ExpenseCategory.gift => 'Gift',
    ExpenseCategory.administration => 'Administration',
    ExpenseCategory.other => 'Other',
  };

  static ExpenseCategory fromName(String? name) => ExpenseCategory.values
      .firstWhere((c) => c.name == name, orElse: () => ExpenseCategory.other);
}
