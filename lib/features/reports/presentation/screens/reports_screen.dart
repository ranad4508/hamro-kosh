import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../fund/providers/fund_providers.dart';

/// SRS §26-§27 — monthly/yearly/fund reports with a supporting chart. The
/// chart currently plots the single live fund-summary snapshot; wiring a
/// month-by-month aggregate collection is the natural next step once
/// Firebase is configured with real historical data.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
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
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
            Tab(text: 'Fund'),
          ]),
          const Expanded(
            child: TabBarView(children: [
              _ReportTab(title: 'This month'),
              _ReportTab(title: 'This year'),
              _FundReportTab(),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ReportTab extends ConsumerWidget {
  const _ReportTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(fundSummaryProvider);

    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (data) {
        final income = data.totalIncome;
        final expenses = data.totalExpenses;
        final maxValue = [income, expenses, 1.0].reduce((a, b) => a > b ? a : b);

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
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: income,
                        color: Theme.of(context).colorScheme.primary,
                        width: 32,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: expenses,
                        color: Theme.of(context).colorScheme.error,
                        width: 32,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReportRow('Total income', CurrencyFormatter.format(income)),
            _ReportRow('Total expenses', CurrencyFormatter.format(expenses)),
            _ReportRow('Total loans disbursed', CurrencyFormatter.format(data.totalLoaned)),
            _ReportRow('Interest earned', CurrencyFormatter.format(data.interestEarned)),
            _ReportRow('Closing balance', CurrencyFormatter.format(data.availableBalance)),
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

    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (data) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ReportRow('Available cash', CurrencyFormatter.format(data.availableBalance)),
          _ReportRow('Outstanding loans', CurrencyFormatter.format(data.outstandingLoans)),
          _ReportRow(
            'Total assets',
            CurrencyFormatter.format(data.availableBalance + data.outstandingLoans),
          ),
          _ReportRow('Total expenses', CurrencyFormatter.format(data.totalExpenses)),
          _ReportRow('Total income', CurrencyFormatter.format(data.totalIncome)),
        ],
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
