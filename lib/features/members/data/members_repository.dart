import 'package:cloud_firestore/cloud_firestore.dart';

import 'member_directory_entry.dart';

class MembersRepository {
  MembersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Every active member (there's no approval queue to filter on — only
  /// `isActive`, since registration and admin-provisioned accounts are both
  /// immediately usable).
  Stream<List<MemberDirectoryEntry>> watchMembers() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) => _excludingSuperAdmin(snapshot.docs));
  }

  Stream<MemberDirectoryEntry?> watchMember(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? MemberDirectoryEntry.fromFirestore(doc.id, doc.data()!)
              : null,
        );
  }

  /// Admin-only: every member regardless of active status (SRS §35 —
  /// member management, enable/disable). The super admin is never included
  /// — SRS.md §58: "not shown to other users," admins included.
  Stream<List<MemberDirectoryEntry>> watchAllMembers() {
    return _firestore
        .collection('users')
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) => _excludingSuperAdmin(snapshot.docs));
  }

  List<MemberDirectoryEntry> _excludingSuperAdmin(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .where((doc) => doc.data()['role'] != 'superAdmin')
        .map((doc) => MemberDirectoryEntry.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> setActive(String uid, bool active) {
    return _firestore.collection('users').doc(uid).update({'isActive': active});
  }
}
