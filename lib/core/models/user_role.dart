/// A user's privilege level, stored on the `users/{uid}.role` Firestore
/// field and used by the router to pick the Member or Admin shell.
///
/// Three roles per SRS.md §58's RBAC addition:
/// - [member] — the default, self-registerable role.
/// - [admin] — day-to-day fund management; can create member accounts.
/// - [superAdmin] — provisioned once, manually, outside the app (see
///   README.md → "Seeding the super admin"); can also create admin
///   accounts, and is never deletable or visible to other users (enforced
///   in `firestore.rules` and by filtering it out of every member/admin
///   list screen — see `RoleVisibility`).
enum UserRole {
  member,
  admin,
  superAdmin;

  static UserRole fromName(String? name) => UserRole.values.firstWhere(
        (role) => role.name == name,
        orElse: () => UserRole.member,
      );

  /// Whether this role can reach the Admin shell (admin dashboard, member/
  /// loan/fund management, etc.) — both privileged roles do.
  bool get canAccessAdminShell => this == admin || this == superAdmin;

  /// Whether this role may provision new admin accounts (only the super
  /// admin can — a plain admin may only create member accounts).
  bool get canCreateAdmins => this == superAdmin;
}
