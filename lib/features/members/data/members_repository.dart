import 'package:cloud_firestore/cloud_firestore.dart';

import 'member_directory_entry.dart';

class MembersRepository {
  MembersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<MemberDirectoryEntry>> watchMembers() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) => _excludingSuperAdmin(snapshot.docs));
  }

  Stream<MemberDirectoryEntry?> watchMember(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists
              ? MemberDirectoryEntry.fromFirestore(doc.id, doc.data()!)
              : null,
        );
  }

  /// Admin-only: every member regardless of approval/active status
  /// (SRS §35 — member management, approve/reject, enable/disable). The
  /// super admin is never included — SRS.md §58: "not shown to other
  /// users," admins included.
  Stream<List<MemberDirectoryEntry>> watchAllMembers() {
    return _firestore.collection('users').orderBy('fullName').snapshots().map(
          (snapshot) => _excludingSuperAdmin(snapshot.docs),
        );
  }

  List<MemberDirectoryEntry> _excludingSuperAdmin(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .where((doc) => doc.data()['role'] != 'superAdmin')
        .map((doc) => MemberDirectoryEntry.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> setApproved(String uid, bool approved) {
    return _firestore.collection('users').doc(uid).update({'isApproved': approved});
  }

  Future<void> setActive(String uid, bool active) {
    return _firestore.collection('users').doc(uid).update({'isActive': active});
  }
}
