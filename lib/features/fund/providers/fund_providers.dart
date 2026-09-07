import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/transaction_type.dart';
import '../data/fund_account.dart';
import '../data/fund_account_repository.dart';
import '../data/fund_repository.dart';
import '../data/fund_summary.dart';
import '../data/fund_transaction.dart';

final fundRepositoryProvider = Provider<FundRepository>((ref) {
  return FundRepository(FirebaseFirestore.instance);
});

final fundAccountRepositoryProvider = Provider<FundAccountRepository>((ref) {
  return FundAccountRepository(FirebaseFirestore.instance);
});

final fundAccountProvider = StreamProvider<FundAccount>((ref) {
  return ref.watch(fundAccountRepositoryProvider).watch();
});

final fundSummaryProvider = StreamProvider<FundSummary>((ref) {
  return ref.watch(fundRepositoryProvider).watchSummary();
});

/// `type: null` returns the unfiltered ledger; used by the dashboard's
/// "recent transactions" preview and the admin fund tabs.
final fundTransactionsProvider =
    StreamProvider.family<List<FundTransaction>, TransactionType?>((ref, type) {
      return ref.watch(fundRepositoryProvider).watchTransactions(type: type);
    });

/// SRS §55 — the full ledger screen's combined type + date-range filter.
typedef LedgerFilter = ({TransactionType? type, DateTimeRange? dateRange});

final ledgerTransactionsProvider =
    StreamProvider.family<List<FundTransaction>, LedgerFilter>((ref, filter) {
      return ref
          .watch(fundRepositoryProvider)
          .watchTransactions(
            type: filter.type,
            dateRange: filter.dateRange,
            limit: 200,
          );
    });

/// SRS §30 — "Fund growth" chart data: total money in vs. out per month for
/// the last [months] months (oldest first), bucketed from the ledger rather
/// than a separate aggregate collection — fine at this app's transaction
/// volume.
typedef MonthlyFundTotal = ({DateTime month, double income, double expense});

final monthlyFundGrowthProvider =
    StreamProvider.family<List<MonthlyFundTotal>, int>((ref, months) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - (months - 1), 1);
      return ref
          .watch(fundRepositoryProvider)
          .watchTransactions(
            dateRange: DateTimeRange(start: start, end: now),
            limit: 1000,
          )
          .map((transactions) {
            final income = List<double>.filled(months, 0);
            final expense = List<double>.filled(months, 0);
            for (final t in transactions) {
              final index =
                  (t.date.year - start.year) * 12 +
                  (t.date.month - start.month);
              if (index < 0 || index >= months) continue;
              if (t.isInflow) {
                income[index] += t.amount;
              } else {
                expense[index] += t.amount;
              }
            }
            return List.generate(months, (i) {
              final month = DateTime(start.year, start.month + i, 1);
              return (month: month, income: income[i], expense: expense[i]);
            });
          });
    });
