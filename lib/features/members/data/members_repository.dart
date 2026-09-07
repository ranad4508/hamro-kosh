import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_role.dart';
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
        .where('isApproved', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) => _excludingSuperAdmin(snapshot.docs));
  }

  /// Admin-only: users awaiting approval.
  Stream<List<MemberDirectoryEntry>> watchPendingMembers() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: false)
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

  /// Admin-only lookup: every user record including Super Admins. Used for
  /// resolving actor names in the Audit Trail.
  Stream<List<MemberDirectoryEntry>> watchAllUsersIncludingSuperAdmin() {
    return _firestore.collection('users').orderBy('fullName').snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => MemberDirectoryEntry.fromFirestore(doc.id, doc.data()),
              )
              .toList(),
    );
  }

  /// Active admins/super-admins — "who can I hand cash to in person"
  /// (`design_spec.md` §5b). Unlike [watchMembers]/[watchAllMembers], the
  /// super admin IS included here: hiding them from the general member
  /// directory is a deliberate privacy/hierarchy choice (SRS.md §58), but
  /// they're still a real person a member can physically hand cash to —
  /// excluding them here would just make that valid option silently
  /// disappear from the list for no reason.
  Stream<List<MemberDirectoryEntry>> watchActiveAdmins() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .where('role', whereIn: ['admin', 'superAdmin'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MemberDirectoryEntry.fromFirestore(doc.id, doc.data()))
              .toList(),
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

  /// SRS §35/§40 — enabling/disabling a member is an audited admin action,
  /// same as any other rule change; batched so the status flip and its
  /// audit entry land together or not at all.
  Future<void> setActiveWithAudit({
    required String uid,
    required bool active,
    required String memberName,
    required String performedBy,
  }) {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {'isActive': active});
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': '${active ? 'Activated' : 'Deactivated'} $memberName',
      'performedBy': performedBy,
      'newValue': active ? 'active' : 'disabled',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  /// SRS §34 — approves a pending registration. Audited.
  Future<void> setApprovedWithAudit({
    required String uid,
    required bool approved,
    required String memberName,
    required String performedBy,
  }) {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'isApproved': approved,
      'isActive': approved, // activate on approval
    });
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': '${approved ? 'Approved' : 'Rejected'} registration for $memberName',
      'performedBy': performedBy,
      'newValue': approved ? 'approved' : 'rejected',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  /// SRS.md §58 RBAC — updates a user's role. Audited.
  Future<void> setRoleWithAudit({
    required String uid,
    required UserRole role,
    required String memberName,
    required String performedBy,
  }) {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {'role': role.name});
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': 'Changed role of $memberName to ${role.name}',
      'performedBy': performedBy,
      'newValue': role.name,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  /// Updates basic member details. Audited.
  Future<void> updateMemberWithAudit({
    required String uid,
    required String fullName,
    required String phone,
    required String performedBy,
  }) {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'fullName': fullName,
      'phone': phone,
    });
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': 'Updated member details for $fullName',
      'performedBy': performedBy,
      'newValue': '$fullName ($phone)',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  /// Deactivates a member and marks as deleted (soft delete). Audited.
  Future<void> deleteMemberWithAudit({
    required String uid,
    required String memberName,
    required String performedBy,
  }) {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'isActive': false,
      'isDeleted': true,
    });
    batch.set(_firestore.collection('audit_log').doc(), {
      'action': 'Soft-deleted member $memberName',
      'performedBy': performedBy,
      'newValue': 'inactive/deleted',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }
}
