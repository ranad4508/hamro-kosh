import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_role.dart';

/// A member's profile document, stored at `users/{uid}` in Firestore.
/// Mirrors SRS §4 (Member Profile) fields that matter for the app shell;
/// the richer financial-profile fields (§32) are computed server-side from
/// the ledger rather than stored redundantly here.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.role,
    required this.memberSince,
    this.isApproved = false,
    this.isActive = true,
    this.mustChangePassword = false,
  });

  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final DateTime memberSince;
  final bool isApproved;
  final bool isActive;

  /// True for accounts an admin created directly (SRS.md §58 RBAC flow) —
  /// the member signed in with a temporary, emailed password and should be
  /// prompted to set their own before continuing.
  final bool mustChangePassword;

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: UserRole.fromName(data['role'] as String?),
      memberSince:
          (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isApproved: data['isApproved'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      mustChangePassword: data['mustChangePassword'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'role': role.name,
    'memberSince': Timestamp.fromDate(memberSince),
    'isApproved': isApproved,
    'isActive': isActive,
    'mustChangePassword': mustChangePassword,
  };
}
