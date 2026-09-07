import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/transaction_type.dart';

/// A single entry in the public financial ledger (SRS §11-§13, §41).
class FundTransaction {
  const FundTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.memberName,
    this.reference,
    this.proofUrl,
    this.category,
    this.recipient,
    this.direction,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String description;
  final String? memberName;
  final String? reference;
  final String? proofUrl;

  /// SRS §17 expense category (Birthday, Dashain, Emergency, ...) — only
  /// populated for `fundExpense` entries.
  final String? category;

  /// Who the money was paid to — only populated for `fundExpense` entries.
  final String? recipient;

  /// SRS §44 — 'credit' or 'debit', only populated for `adjustment` entries
  /// (a correction can go either way, unlike every other transaction type,
  /// which has a fixed in/out direction).
  final String? direction;

  /// Whether this entry increases (true) or decreases (false) the available
  /// fund balance. Every type except `adjustment` has a fixed direction
  /// ([TransactionType.isInflow]); a correction's direction depends on the
  /// specific mistake it's fixing, so it's read from [direction] instead.
  bool get isInflow =>
      type == TransactionType.adjustment ? direction != 'debit' : type.isInflow;

  factory FundTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    return FundTransaction(
      id: id,
      type: TransactionType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => TransactionType.otherIncome,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String? ?? '',
      memberName: data['memberName'] as String?,
      reference: data['reference'] as String?,
      proofUrl: data['proofUrl'] as String?,
      category: data['category'] as String?,
      recipient: data['recipient'] as String?,
      direction: data['direction'] as String?,
    );
  }
}
