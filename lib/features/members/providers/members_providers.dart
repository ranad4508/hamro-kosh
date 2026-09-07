import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/member_directory_entry.dart';
import '../data/members_repository.dart';

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(FirebaseFirestore.instance);
});

final membersProvider = StreamProvider<List<MemberDirectoryEntry>>((ref) {
  return ref.watch(membersRepositoryProvider).watchMembers();
});

final memberDetailProvider =
    StreamProvider.family<MemberDirectoryEntry?, String>((ref, uid) {
      return ref.watch(membersRepositoryProvider).watchMember(uid);
    });

/// Admin-only listing (includes pending/inactive members).
final allMembersProvider = StreamProvider<List<MemberDirectoryEntry>>((ref) {
  return ref.watch(membersRepositoryProvider).watchAllMembers();
});

/// Active admins/super-admins — who a member can hand cash to in person
/// (`design_spec.md` §5b: "only admins may take cash"). Derived from the
/// regular (approved-only) directory rather than a separate query.
final activeAdminsProvider = Provider<AsyncValue<List<MemberDirectoryEntry>>>((
  ref,
) {
  final members = ref.watch(membersProvider);
  return members.whenData(
    (list) => list
        .where((m) => m.isActive && m.role.canAccessAdminShell)
        .toList(),
  );
});
