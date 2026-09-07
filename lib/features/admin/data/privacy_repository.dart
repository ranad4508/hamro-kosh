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

  /// SRS §40/§47 — a visibility-rule change is exactly the kind of
  /// admin-mutable value that needs an audit entry ("who can see what"
  /// changing is as significant as a contribution-minimum change);
  /// batched so the setting and its audit entry commit together.
  Future<void> updateWithAudit({
    required PrivacySettings settings,
    required String settingLabel,
    required bool newValue,
    required String performedBy,
  }) {
    final batch = _firestore.batch();
    batch.set(_doc, settings.toFirestore(), SetOptions(merge: true));
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': 'Set "$settingLabel" to ${newValue ? 'On' : 'Off'}',
      'performedBy': performedBy,
      'newValue': newValue ? 'On' : 'Off',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }
}
