import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/user_role.dart';

/// Where a member's account currently stands — derived from [AppUser]
/// rather than re-checked inline by every screen that needs it (the old
/// `AccountPendingScreen` derived this exact three-way split directly in
/// its `build()` method, a business-logic-in-a-widget smell this rewrite
/// avoids repeating).
///
/// There is no approval step and no "treasurer" role — only member/admin/
/// superAdmin exist, and anyone who registers (or is created directly by an
/// admin/super admin) is immediately active.
enum AccountStatus {
  /// Signed in, but no Firestore profile exists at all — e.g. an Auth user
  /// created directly in the Firebase console, or an unrecoverable
  /// registration failure. Treated the same as "not usable" by the router.
  noProfile,

  /// An admin disabled this account (SRS §35).
  disabled,

  /// Everything checks out — usable app account.
  active,
}

/// A member's Firestore profile (`users/{uid}`) — SRS §3, §4, and the
/// three-tier RBAC addition in SRS.md §58.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone,
    this.photoUrl,
    this.memberSince,
    this.mustChangePassword = false,
  });

  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final DateTime? memberSince;

  /// SRS §35 — an admin-disabled account stays on record (never deleted)
  /// but can no longer sign in to a usable shell.
  final bool isActive;

  /// Set on admin-provisioned accounts (`createUserAccount`); forces the
  /// `ForcedPasswordChangeScreen` before the member reaches either shell.
  final bool mustChangePassword;

  AccountStatus get status =>
      isActive ? AccountStatus.active : AccountStatus.disabled;

  String get initials {
    final parts = fullName.trim().split(
      RegExp(r'\s+'),
    )..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? photoUrl,
    bool? mustChangePassword,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      isActive: isActive,
      memberSince: memberSince,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: UserRole.fromName(data['role'] as String?),
      isActive: data['isActive'] as bool? ?? true,
      memberSince: (data['memberSince'] as Timestamp?)?.toDate(),
      mustChangePassword: data['mustChangePassword'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fullName': fullName,
    if (phone != null) 'phone': phone,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'mustChangePassword': mustChangePassword,
  };
}
