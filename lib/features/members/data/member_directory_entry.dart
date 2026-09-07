import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_role.dart';

/// A member as shown in the community directory (SRS §31-§32). Deliberately
/// narrower than [AppUser] — only fields cleared for community-wide display
/// are included here. Financial figures (total contributed, active loan
/// status) aren't stored on this document at all — they're computed from
/// the `contributions`/`loans` collections by
/// `memberVerifiedContributionsTotalProvider` / `memberHasActiveLoanProvider`
/// so there's a single source of truth rather than a denormalized copy that
/// could drift.
///
/// `phone` is included here (unlike email, which stays admin/self-only) so
/// SRS §29's admin-configurable "show phone" privacy toggle has something
/// real to gate — see `PrivacySettings.showPhoneNumber` and where the UI
/// actually displays it (Member Detail). This is a UI-layer gate, not a
/// Firestore rule: fine for this app's small-trusted-community threat
/// model, not a hard boundary against a technically determined member.
class MemberDirectoryEntry {
  const MemberDirectoryEntry({
    required this.uid,
    required this.fullName,
    required this.memberSince,
    this.photoUrl,
    this.phone,
    this.isActive = true,
    this.role = UserRole.member,
  });

  final String uid;
  final String fullName;
  final DateTime memberSince;
  final String? photoUrl;
  final String? phone;
  final bool isActive;

  /// SRS.md §58 RBAC hierarchy — lets Manage Members scope who can
  /// enable/disable whom: an admin manages `member` accounts only, and only
  /// a super admin manages `admin` accounts (see `AdminMembersScreen` and
  /// the matching `firestore.rules` restriction on `users/{userId}.update`).
  final UserRole role;

  factory MemberDirectoryEntry.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return MemberDirectoryEntry(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      memberSince:
          (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
      phone: data['phone'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      role: UserRole.fromName(data['role'] as String?),
    );
  }
}
