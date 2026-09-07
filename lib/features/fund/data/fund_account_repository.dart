import 'package:cloud_firestore/cloud_firestore.dart';

import 'fund_account.dart';

class FundAccountRepository {
  FundAccountRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('settings').doc('fund_account');

  Stream<FundAccount> watch() {
    return _doc.snapshots().map(
      (doc) => doc.exists
          ? FundAccount.fromFirestore(doc.data()!)
          : FundAccount.defaults,
    );
  }

  Future<void> update(FundAccount account) {
    return _doc.set(account.toFirestore(), SetOptions(merge: true));
  }
}
