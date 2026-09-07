import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/models/transaction_type.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../data/report_csv_export.dart';

/// SRS §26-§27, §30 — monthly/yearly reports scoped to their actual period
/// (computed from the ledger, not the single all-time fund snapshot), plus
/// the all-time fund position and a "fund growth" trend chart.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () => exportFundReportCsv(ref, context),
          ),
        ],
      ),
      body: const ReportsView(),
    );
  }
}

/// The tab bar + tab bodies, factored out so both the member Reports
/// screen and the admin Reports screen (which needs [AdminMoreMenu] in its
/// own app bar) can share one implementation.
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
              Tab(text: 'Fund'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PeriodReportTab(
                  title: DateFormatter.monthYear(now),
                  start: DateTime(now.year, now.month, 1),
                ),
                _PeriodReportTab(
                  title: '${now.year}',
                  start: DateTime(now.year, 1, 1),
                ),
                const _FundReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodReportTab extends ConsumerWidget {
  const _PeriodReportTab({required this.title, required this.start});

  final String title;
  final DateTime start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(
      ledgerTransactionsProvider((
        type: null,
        dateRange: DateTimeRange(start: start, end: DateTime.now()),
      )),
    );

    return transactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        final income = items
            .where((t) => t.isInflow)
            .fold<double>(0, (s, t) => s + t.amount);
        final expenses = items
            .where((t) => !t.isInflow)
            .fold<double>(0, (s, t) => s + t.amount);
        final loansDisbursed = items
            .where((t) => t.type == TransactionType.loanDisbursement)
            .fold<double>(0, (s, t) => s + t.amount);
        final interest = items
            .where((t) => t.type == TransactionType.interestPayment)
            .fold<double>(0, (s, t) => s + t.amount);
        final maxValue = [
          income,
          expenses,
          1.0,
        ].reduce((a, b) => a > b ? a : b);

        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'No activity in $title yet',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          value == 0 ? 'Income' : 'Expenses',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: Theme.of(context).colorScheme.primary,
                          width: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: expenses,
                          color: Theme.of(context).colorScheme.error,
                          width: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportRow('Total income', CurrencyFormatter.format(income)),
            _ReportRow('Total expenses', CurrencyFormatter.format(expenses)),
            _ReportRow(
              'Loans disbursed',
              CurrencyFormatter.format(loansDisbursed),
            ),
            _ReportRow('Interest earned', CurrencyFormatter.format(interest)),
            _ReportRow(
              'Net for the period',
              CurrencyFormatter.format(income - expenses),
            ),
          ],
        );
      },
    );
  }
}

class _FundReportTab extends ConsumerWidget {
  const _FundReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(fundSummaryProvider);
    final growth = ref.watch(monthlyFundGrowthProvider(6));

    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (data) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ReportRow(
            'Available cash',
            CurrencyFormatter.format(data.availableBalance),
          ),
          _ReportRow(
            'Outstanding loans',
            CurrencyFormatter.format(data.outstandingLoans),
          ),
          _ReportRow(
            'Total fund position',
            CurrencyFormatter.format(
              data.availableBalance + data.outstandingLoans,
            ),
          ),
          _ReportRow(
            'Total expenses (all time)',
            CurrencyFormatter.format(data.totalExpenses),
          ),
          _ReportRow(
            'Total income (all time)',
            CurrencyFormatter.format(data.totalIncome),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Fund growth', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Money in per month, last 6 months',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          switch (growth) {
            AsyncData(:final value) => _FundGrowthChart(months: value),
            AsyncError() => const SizedBox.shrink(),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}

class _FundGrowthChart extends StatelessWidget {
  const _FundGrowthChart({required this.months});

  final List<MonthlyFundTotal> months;

  @override
  Widget build(BuildContext context) {
    final maxValue = months
        .map((m) => m.income)
        .fold<double>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormatter.monthAbbr(months[index].month),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: [
            for (var i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: months[i].income,
                    color: Theme.of(context).colorScheme.primary,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
