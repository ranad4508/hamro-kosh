import 'package:cloud_firestore/cloud_firestore.dart';

/// A member as shown in the community directory (SRS §31-§32). Deliberately
/// narrower than [AppUser] — only fields cleared for community-wide display
/// under the configured privacy rules are included here.
class MemberDirectoryEntry {
  const MemberDirectoryEntry({
    required this.uid,
    required this.fullName,
    required this.memberSince,
    this.photoUrl,
    this.totalContributed,
    this.hasActiveLoan = false,
    this.isActive = true,
    this.isApproved = true,
  });

  final String uid;
  final String fullName;
  final DateTime memberSince;
  final String? photoUrl;
  final double? totalContributed;
  final bool hasActiveLoan;
  final bool isActive;
  final bool isApproved;

  factory MemberDirectoryEntry.fromFirestore(String uid, Map<String, dynamic> data) {
    return MemberDirectoryEntry(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      memberSince: (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
      totalContributed: (data['totalContributed'] as num?)?.toDouble(),
      hasActiveLoan: data['hasActiveLoan'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      isApproved: data['isApproved'] as bool? ?? true,
    );
  }
}
