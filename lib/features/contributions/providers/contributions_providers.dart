import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/loan_status.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/contribution.dart';
import '../data/contributions_repository.dart';

final contributionsRepositoryProvider = Provider<ContributionsRepository>((ref) {
  return ContributionsRepository(FirebaseFirestore.instance);
});

final myContributionsProvider = StreamProvider<List<Contribution>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(contributionsRepositoryProvider).watchMyContributions(uid);
});

/// Admin-only, optionally filtered by [ContributionStatus].
final allContributionsProvider =
    StreamProvider.family<List<Contribution>, ContributionStatus?>((ref, status) {
  return ref.watch(contributionsRepositoryProvider).watchAllContributions(status: status);
});
