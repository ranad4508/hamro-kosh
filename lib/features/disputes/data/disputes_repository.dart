import 'package:cloud_firestore/cloud_firestore.dart';

import 'dispute.dart';

class DisputesRepository {
  DisputesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _disputes =>
      _firestore.collection('disputes');

  Stream<List<Dispute>> watchMyDisputes(String uid) {
    return _disputes
        .where('memberUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Dispute.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Admin-only: every dispute, most recent first.
  Stream<List<Dispute>> watchAllDisputes() {
    return _disputes
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Dispute.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> submit({
    required String uid,
    required String memberName,
    required String subject,
    required String description,
  }) {
    return _disputes.add(
      Dispute(
        id: '',
        memberUid: uid,
        memberName: memberName,
        subject: subject,
        description: description,
        status: DisputeStatus.open,
        createdAt: DateTime.now(),
      ).toFirestore(),
    );
  }

  /// Admin-only: marks a dispute resolved with an optional response visible
  /// to the member who raised it. Batched with an audit entry (SRS §40/§49
  /// — dispute resolution is an admin action on a member's own complaint,
  /// same bar as any other admin-mutable value) so the resolution and its
  /// record land together.
  Future<void> resolve({
    required String disputeId,
    required String subject,
    required String performedBy,
    String? adminResponse,
  }) {
    final batch = _firestore.batch();
    batch.update(_disputes.doc(disputeId), {
      'status': 'resolved',
      'adminResponse': adminResponse,
      'resolvedAt': Timestamp.now(),
    });
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': 'Resolved dispute: $subject',
      'performedBy': performedBy,
      'reason': adminResponse,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }
}
