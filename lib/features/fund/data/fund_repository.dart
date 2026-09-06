import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/transaction_type.dart';
import 'fund_summary.dart';
import 'fund_transaction.dart';

/// Reads the aggregated fund summary and the transaction ledger. Writes
/// (recording a new transaction, editing/approving one) live in the admin
/// feature, which is the only place SRS §51 rule 9 ("only authorized admins
/// can approve financial transactions") allows them to originate.
class FundRepository {
  FundRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<FundSummary> watchSummary() {
    return _firestore.collection('fund').doc('summary').snapshots().map(
          (doc) => doc.exists
              ? FundSummary.fromFirestore(doc.data()!)
              : FundSummary.zero,
        );
  }

  Stream<List<FundTransaction>> watchTransactions({
    int limit = 50,
    TransactionType? type,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FundTransaction.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}
