import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/dispute.dart';
import '../data/disputes_repository.dart';

final disputesRepositoryProvider = Provider<DisputesRepository>((ref) {
  return DisputesRepository(FirebaseFirestore.instance);
});

final myDisputesProvider = StreamProvider<List<Dispute>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(disputesRepositoryProvider).watchMyDisputes(uid);
});

/// Admin-only.
final allDisputesProvider = StreamProvider<List<Dispute>>((ref) {
  return ref.watch(disputesRepositoryProvider).watchAllDisputes();
});
