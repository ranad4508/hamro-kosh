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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Contribution.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
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
  Stream<List<Contribution>> watchAllContributions({
    ContributionStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('contributions')
        .orderBy('date', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Contribution.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  // Verifying/rejecting a contribution is intentionally NOT a method here:
  // it goes through the `verifyContribution` Cloud Function
  // (`CloudFunctionsService.verifyContribution`) instead of a direct
  // Firestore write, since it also has to record a ledger entry and update
  // the fund total — see functions/index.js.
}
