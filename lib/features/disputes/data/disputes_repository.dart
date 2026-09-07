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
  /// to the member who raised it.
  Future<void> resolve(String disputeId, {String? adminResponse}) {
    return _disputes.doc(disputeId).update({
      'status': 'resolved',
      'adminResponse': adminResponse,
      'resolvedAt': Timestamp.now(),
    });
  }
}
