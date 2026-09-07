import 'package:flutter/material.dart';

/// SRS §11 — the full set of fund transaction types recorded in the
/// financial ledger.
enum TransactionType {
  monthlyContribution,
  specialContribution,
  loanDisbursement,
  loanRepayment,
  interestPayment,
  fundExpense,
  refund,
  adjustment,
  otherIncome,
  otherExpenditure;

  /// Whether this transaction type increases (true) or decreases (false)
  /// the available fund balance.
  bool get isInflow => switch (this) {
    TransactionType.monthlyContribution => true,
    TransactionType.specialContribution => true,
    TransactionType.loanRepayment => true,
    TransactionType.interestPayment => true,
    TransactionType.otherIncome => true,
    TransactionType.refund => true,
    TransactionType.loanDisbursement => false,
    TransactionType.fundExpense => false,
    TransactionType.otherExpenditure => false,
    TransactionType.adjustment => true,
  };

  IconData get icon => switch (this) {
    TransactionType.monthlyContribution => Icons.calendar_month,
    TransactionType.specialContribution => Icons.celebration,
    TransactionType.loanDisbursement => Icons.call_made,
    TransactionType.loanRepayment => Icons.call_received,
    TransactionType.interestPayment => Icons.percent,
    TransactionType.fundExpense => Icons.receipt_long,
    TransactionType.refund => Icons.replay,
    TransactionType.adjustment => Icons.tune,
    TransactionType.otherIncome => Icons.add_card,
    TransactionType.otherExpenditure => Icons.remove_circle_outline,
  };
}
