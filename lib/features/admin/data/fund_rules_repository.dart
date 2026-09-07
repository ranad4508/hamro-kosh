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

  Future<void> update(FundRules rules) {
    return _doc.set(rules.toFirestore(), SetOptions(merge: true));
  }

  /// SRS §39 — rule changes must also append an audit entry, and the two
  /// writes must land together: a batch means either both the rule change
  /// and its audit trail persist, or neither does — never a rule change
  /// with no record of who changed it or why.
  Future<void> updateWithAudit({
    required FundRules rules,
    required String action,
    required String performedBy,
    String? previousValue,
    String? newValue,
    String? reason,
  }) {
    final batch = _firestore.batch();
    batch.set(_doc, rules.toFirestore(), SetOptions(merge: true));
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': action,
      'performedBy': performedBy,
      'previousValue': previousValue,
      'newValue': newValue,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }
}
