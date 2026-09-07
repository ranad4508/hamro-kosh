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
