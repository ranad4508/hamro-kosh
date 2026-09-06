import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/transaction_type.dart';
import '../data/fund_repository.dart';
import '../data/fund_summary.dart';
import '../data/fund_transaction.dart';

final fundRepositoryProvider = Provider<FundRepository>((ref) {
  return FundRepository(FirebaseFirestore.instance);
});

final fundSummaryProvider = StreamProvider<FundSummary>((ref) {
  return ref.watch(fundRepositoryProvider).watchSummary();
});

/// `type: null` returns the unfiltered ledger; used by both the dashboard's
/// "recent transactions" preview and the full ledger/filter screen.
final fundTransactionsProvider = StreamProvider.family<
    List<FundTransaction>, TransactionType?>((ref, type) {
  return ref.watch(fundRepositoryProvider).watchTransactions(type: type);
});
