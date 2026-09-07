import 'package:cloud_firestore/cloud_firestore.dart';

import 'fund_rules.dart';

class FundRulesRepository {
  FundRulesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('settings').doc('fund_rules');

  Stream<FundRules> watch() {
    return _doc.snapshots().map(
      (doc) => doc.exists
          ? FundRules.fromFirestore(doc.data()!)
          : FundRules.defaults,
    );
  }

  /// SRS §39 — rule changes should ideally also append an audit entry;
  /// that write happens alongside this one from the settings screen so the
  /// "old value / new value / changed by / reason" trail (§39, §40) is
  /// captured at the point of change rather than inferred after the fact.
  Future<void> update(FundRules rules) {
    return _doc.set(rules.toFirestore(), SetOptions(merge: true));
  }
}
