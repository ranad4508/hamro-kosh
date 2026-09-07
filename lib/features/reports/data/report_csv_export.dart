import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/csv_export_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../fund/data/fund_summary.dart';
import '../../fund/data/fund_transaction.dart';
import '../../fund/providers/fund_providers.dart';

/// SRS §43 — "monthly/yearly/complete fund reports" as one combined CSV
/// (current month, current year, and the all-time fund position), used by
/// both the member and admin Reports screens.
Future<void> exportFundReportCsv(WidgetRef ref, BuildContext context) async {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final yearStart = DateTime(now.year, 1, 1);

  final List<FundTransaction> monthly;
  final List<FundTransaction> yearly;
  final FundSummary summary;
  try {
    monthly = await ref.read(
      ledgerTransactionsProvider((
        type: null,
        dateRange: DateTimeRange(start: monthStart, end: now),
      )).future,
    );
    yearly = await ref.read(
      ledgerTransactionsProvider((
        type: null,
        dateRange: DateTimeRange(start: yearStart, end: now),
      )).future,
    );
    summary = await ref.read(fundSummaryProvider.future);
  } catch (error) {
    if (context.mounted) {
      AppSnackbar.showError(
        context,
        title: 'Could not export',
        message: '$error',
      );
    }
    return;
  }

  double sumIn(List<FundTransaction> items) =>
      items.where((t) => t.isInflow).fold(0, (s, t) => s + t.amount);
  double sumOut(List<FundTransaction> items) =>
      items.where((t) => !t.isInflow).fold(0, (s, t) => s + t.amount);

  final rows = <List<dynamic>>[
    ['Hamro Kosh — Fund Report', DateFormatter.dateTime(now)],
    [],
    ['Monthly report', DateFormatter.monthYear(now)],
    ['Total income', sumIn(monthly).toStringAsFixed(2)],
    ['Total expenses', sumOut(monthly).toStringAsFixed(2)],
    ['Net for the period', (sumIn(monthly) - sumOut(monthly)).toStringAsFixed(2)],
    [],
    ['Yearly report', '${now.year}'],
    ['Total income', sumIn(yearly).toStringAsFixed(2)],
    ['Total expenses', sumOut(yearly).toStringAsFixed(2)],
    ['Net for the period', (sumIn(yearly) - sumOut(yearly)).toStringAsFixed(2)],
    [],
    ['Complete fund report (all time)'],
    ['Available cash', summary.availableBalance.toStringAsFixed(2)],
    ['Outstanding loans', summary.outstandingLoans.toStringAsFixed(2)],
    [
      'Total fund position',
      (summary.availableBalance + summary.outstandingLoans).toStringAsFixed(2),
    ],
    ['Total income (all time)', summary.totalIncome.toStringAsFixed(2)],
    ['Total expenses (all time)', summary.totalExpenses.toStringAsFixed(2)],
    ['Total loaned (all time)', summary.totalLoaned.toStringAsFixed(2)],
    ['Interest earned (all time)', summary.interestEarned.toStringAsFixed(2)],
  ];

  await CsvExportService.exportAndShare(
    fileName:
        'hamro_kosh_fund_report_${now.toIso8601String().split('T').first}.csv',
    rows: rows,
    shareText: 'Hamro Kosh fund report',
  );

  if (context.mounted) {
    AppSnackbar.showSuccess(
      context,
      title: 'Export ready',
      message: 'Monthly, yearly, and all-time fund report exported.',
    );
  }
}
