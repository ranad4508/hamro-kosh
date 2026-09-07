import 'package:cloud_firestore/cloud_firestore.dart';

import 'audit_log_entry.dart';

class AuditRepository {
  AuditRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Appends an entry directly from the client — used only for the handful
  /// of admin actions that are plain settings writes rather than a
  /// money-moving Cloud Function call (which write their own audit entry
  /// server-side alongside the ledger/fund-total change). `firestore.rules`
  /// allows this for any active admin (`audit_log`'s `create` rule).
  Future<void> write({
    required String action,
    required String performedBy,
    String? previousValue,
    String? newValue,
    String? reason,
  }) {
    return _firestore.collection('audit_log').add({
      'action': action,
      'performedBy': performedBy,
      'previousValue': previousValue,
      'newValue': newValue,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AuditLogEntry>> watchLog({int limit = 100}) {
    return _firestore
        .collection('audit_log')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogEntry.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}
