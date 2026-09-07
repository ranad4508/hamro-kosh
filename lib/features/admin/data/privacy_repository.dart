import 'package:cloud_firestore/cloud_firestore.dart';

import 'privacy_settings.dart';

class PrivacyRepository {
  PrivacyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('settings').doc('privacy');

  Stream<PrivacySettings> watch() {
    return _doc.snapshots().map(
      (doc) => doc.exists
          ? PrivacySettings.fromFirestore(doc.data()!)
          : PrivacySettings.defaults,
    );
  }

  Future<void> update(PrivacySettings settings) {
    return _doc.set(settings.toFirestore(), SetOptions(merge: true));
  }
}
