import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/loan_status.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/loan.dart';
import '../data/loans_repository.dart';

final loansRepositoryProvider = Provider<LoansRepository>((ref) {
  return LoansRepository(FirebaseFirestore.instance);
});

final myLoansProvider = StreamProvider<List<Loan>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(loansRepositoryProvider).watchMyLoans(uid);
});

final loanDetailProvider = StreamProvider.family<Loan?, String>((ref, loanId) {
  return ref.watch(loansRepositoryProvider).watchLoan(loanId);
});

/// Admin-only: all loans, optionally filtered by status.
final allLoansProvider = StreamProvider.family<List<Loan>, LoanStatus?>((ref, status) {
  return ref.watch(loansRepositoryProvider).watchAllLoans(status: status);
});
