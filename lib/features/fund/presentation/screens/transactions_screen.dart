import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/transaction_type.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bs_date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/corrected_entry_tile.dart';
import '../../../../core/widgets/date_filter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/fund_transaction.dart';
import '../../providers/fund_providers.dart';
import '../widgets/transaction_tile.dart';

enum _LedgerFilter { all, moneyIn, moneyOut }

/// SRS §11-13, §42, §55 — the full, permanent ledger (`design_spec.md` §2d):
/// an All/Money-in/Money-out split, a summary allocation bar, entries
/// grouped by month, and corrections shown as a struck-through original
/// with the fix nested beneath it rather than a separate, disconnected row.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _LedgerFilter _filter = _LedgerFilter.all;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(
      ledgerTransactionsProvider((type: null, dateRange: _dateRange)),
    );
    final summary = ref.watch(fundSummaryProvider);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: transactions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppErrorState(message: '$error'),
          data: (all) {
            final visible = switch (_filter) {
              _LedgerFilter.all => all,
              _LedgerFilter.moneyIn => all.where((t) => t.isInflow).toList(),
              _LedgerFilter.moneyOut => all.where((t) => !t.isInflow).toList(),
            };

            final adjustmentByOriginalId = {
              for (final a in all.where(
                (t) => t.type == TransactionType.adjustment && t.reference != null,
              ))
                a.reference!: a,
            };
            final adjustmentIds = all
                .where((t) => t.type == TransactionType.adjustment)
                .map((t) => t.id)
                .toSet();

            final grouped = <String, List<FundTransaction>>{};
            for (final t in visible) {
              if (adjustmentIds.contains(t.id)) continue;
              grouped.putIfAbsent(BsDateFormatter.monthYear(t.date), () => []).add(t);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ledger', style: Theme.of(context).textTheme.headlineSmall),
                            Text(
                              '${all.length} entries · nothing ever removed',
                              style: TextStyle(fontSize: 12, color: colors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      DateFilter(
                        value: _dateRange,
                        onChanged: (range) => setState(() => _dateRange = range),
                      ),
                      IconButton(
                        tooltip: 'Export CSV',
                        icon: const Icon(Icons.ios_share_outlined),
                        onPressed: () => _exportLedgerCsv(context, visible),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: SegmentedButton<_LedgerFilter>(
                    segments: const [
                      ButtonSegment(value: _LedgerFilter.all, label: Text('All')),
                      ButtonSegment(value: _LedgerFilter.moneyIn, label: Text('Money in')),
                      ButtonSegment(value: _LedgerFilter.moneyOut, label: Text('Money out')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) => setState(() => _filter = s.first),
                  ),
                ),
                if (summary.value != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _LedgerSummaryCard(
                      totalIn: summary.value!.totalIncome,
                      totalOut: summary.value!.totalExpenses,
                      inHand: summary.value!.availableBalance,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: grouped.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: _dateRange != null || _filter != _LedgerFilter.all
                              ? 'No matching transactions'
                              : 'No transactions yet',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          children: [
                            for (final entry in grouped.entries) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.6,
                                    color: colors.textQuaternary,
                                  ),
                                ),
                              ),
                              for (final t in entry.value) ...[
                                Builder(
                                  builder: (context) {
                                    final correction = adjustmentByOriginalId[t.id];
                                    if (correction == null) {
                                      return TransactionTile(transaction: t);
                                    }
                                    final originalSigned =
                                        t.isInflow ? t.amount : -t.amount;
                                    final delta = correction.isInflow
                                        ? correction.amount
                                        : -correction.amount;
                                    return CorrectedEntryTile(
                                      originalDescription: t.description,
                                      originalAmount: originalSigned,
                                      correctedAmount: originalSigned + delta,
                                      reason: correction.description,
                                      correctedBy: 'an admin',
                                      correctedOnLabel: DateFormatter.shortDate(
                                        correction.date,
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: AppSpacing.lg),
                              ],
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LedgerSummaryCard extends StatelessWidget {
  const _LedgerSummaryCard({
    required this.totalIn,
    required this.totalOut,
    required this.inHand,
  });

  final double totalIn;
  final double totalOut;
  final double inHand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = totalIn + totalOut == 0 ? 1 : totalIn + totalOut;
    final inFraction = (totalIn / total).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryCell('Total in', CurrencyFormatter.format(totalIn), colors.accentLight),
              _SummaryCell('Total out', CurrencyFormatter.format(totalOut), colors.textSecondary),
              _SummaryCell('In hand', CurrencyFormatter.format(inHand), colors.textPrimary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: inFraction,
              minHeight: 6,
              backgroundColor: colors.surfaceSunken,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'In hand = everything in, less everything spent, less what is '
            'still out on loan.',
            style: TextStyle(fontSize: 11, color: colors.textQuaternary),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: context.colors.textQuaternary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: color),
          ),
        ],
      ),
    );
  }
}

/// SRS §43 — exports the currently filtered ledger view as CSV.
Future<void> _exportLedgerCsv(
  BuildContext context,
  List<FundTransaction> items,
) async {
  if (items.isEmpty) return;
  final rows = <List<dynamic>>[
    ['Date', 'Type', 'Description', 'Member/Recipient', 'Direction', 'Amount (NPR)'],
    for (final t in items)
      [
        DateFormatter.shortDate(t.date),
        t.type.name,
        t.description,
        t.memberName ?? t.recipient ?? '',
        t.isInflow ? 'In' : 'Out',
        t.amount.toStringAsFixed(2),
      ],
  ];
  await CsvExportService.exportAndShare(
    fileName:
        'hamro_kosh_ledger_${DateTime.now().toIso8601String().split('T').first}.csv',
    rows: rows,
    shareText: 'Hamro Kosh financial ledger export',
  );
  if (context.mounted) {
    AppSnackbar.showSuccess(
      context,
      title: 'Export ready',
      message: '${items.length} transactions exported.',
    );
  }
}
