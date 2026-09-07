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
    );
  }
}
