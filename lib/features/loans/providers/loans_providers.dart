import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/loan_status.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/loan.dart';
import '../data/loan_repayment.dart';
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
final allLoansProvider = StreamProvider.family<List<Loan>, LoanStatus?>((
  ref,
  status,
) {
  return ref.watch(loansRepositoryProvider).watchAllLoans(status: status);
});

/// Drives the "N of `maxConcurrentLoans` slots available" indicator on the
/// Request Loan screen (SRS §17-§19's fund-wide concurrent-loan cap).
final outstandingLoanCountProvider = StreamProvider<int>((ref) {
  return ref.watch(loansRepositoryProvider).watchOutstandingLoanCount();
});

/// Backs the member directory's "has an outstanding loan" indicator (SRS
/// §31) — one shared listener for the whole list rather than one per row.
final outstandingBorrowerIdsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(loansRepositoryProvider).watchOutstandingBorrowerIds();
});

/// Whether a specific member currently has an outstanding loan — used by
/// Member Detail (SRS §32), where only one member's status is needed.
final memberHasActiveLoanProvider = StreamProvider.family<bool, String>((
  ref,
  uid,
) {
  return ref
      .watch(loansRepositoryProvider)
      .watchMyLoans(uid)
      .map((loans) => loans.any((l) => l.countsTowardConcurrentCap));
});

/// SRS §21 — a single loan's repayment history, newest first.
final loanRepaymentsProvider =
    StreamProvider.family<List<LoanRepayment>, String>((ref, loanId) {
      return ref.watch(loansRepositoryProvider).watchRepaymentsForLoan(loanId);
    });

/// Admin-only: every repayment awaiting verification, across all loans.
final pendingRepaymentsProvider = StreamProvider<List<LoanRepayment>>((ref) {
  return ref.watch(loansRepositoryProvider).watchPendingRepayments();
});
