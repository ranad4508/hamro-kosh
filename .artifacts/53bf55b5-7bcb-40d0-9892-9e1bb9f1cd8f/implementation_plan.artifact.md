# Implementation Plan - Enhancing Actor Display in Audit Trail

The user wants the Audit Trail to show the names and titles (roles) of the actors instead of their IDs (UIDs).

## User Review Required

> [!IMPORTANT]
> - I will be exposing Super Admin names in the Audit Trail to Admins. This is necessary for accurate auditing (knowing which Super Admin performed an action), even though Super Admins are hidden from the general member directory.
> - I will be adding a role label (e.g., "Admin", "Super Admin") next to the actor's name.

## Proposed Changes

### Members Feature

#### [MODIFY] [members_repository.dart](file:///D:/Flutter Projects/hamro_kosh/lib/features/members/data/members_repository.dart)
- Add `watchAllUsersIncludingSuperAdmin()` method to fetch every user record for name/role resolution in the audit log.

#### [MODIFY] [members_providers.dart](file:///D:/Flutter Projects/hamro_kosh/lib/features/members/providers/members_providers.dart)
- Add `allUsersLookupProvider` (StreamProvider) that calls the new repository method.

### Admin Feature

#### [MODIFY] [admin_audit_screen.dart](file:///D:/Flutter Projects/hamro_kosh/lib/features/admin/presentation/screens/admin_audit_screen.dart)
- Use `allUsersLookupProvider` instead of `allMembersProvider`.
- Update the `actorName` helper to return both the name and the role in parentheses (e.g., "Sabin Karki (Admin)").
- Update `_AuditTile` and `_AuditDetailSheet` to handle the enhanced actor information.

## Verification Plan

### Manual Verification
1.  **Audit Trail List:** Open the Audit Trail as an Admin. Verify that entries show "Name (Role)" instead of UIDs or just names.
2.  **Audit Details:** Tap an entry and verify the "Actor" field in the bottom sheet also shows the name and role.
3.  **Super Admin Actions:** Perform an action as a Super Admin and verify that an Admin can see the Super Admin's name in the audit log.

### Automated Tests
- Run `flutter analyze` to ensure no regressions.
