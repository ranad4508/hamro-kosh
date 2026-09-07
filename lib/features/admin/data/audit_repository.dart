import 'package:cloud_firestore/cloud_firestore.dart';

import 'audit_log_entry.dart';

class AuditRepository {
  AuditRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
