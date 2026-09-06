import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/loan_status.dart';
import 'contribution.dart';

class ContributionsRepository {
  ContributionsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Contribution>> watchMyContributions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('contributions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Contribution.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Submits a contribution for admin verification (SRS §7 — "view
  /// contribution status", pending until an admin confirms it).
  Future<void> submit(String uid, Contribution contribution) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('contributions')
        .add(contribution.toFirestore());
  }

  /// Admin-only: every member's contributions via a collection-group query,
  /// optionally filtered to pending ones awaiting verification (SRS §38).
  Stream<List<Contribution>> watchAllContributions({ContributionStatus? status}) {
    Query<Map<String, dynamic>> query =
        _firestore.collectionGroup('contributions').orderBy('date', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Contribution.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  Future<void> setStatus({
    required String memberUid,
    required String contributionId,
    required ContributionStatus status,
  }) {
    return _firestore
        .collection('users')
        .doc(memberUid)
        .collection('contributions')
        .doc(contributionId)
        .update({'status': status.name});
  }
}
