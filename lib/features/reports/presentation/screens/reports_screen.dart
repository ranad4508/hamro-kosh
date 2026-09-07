import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/finance_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/models/transaction_type.dart';
import '../../../fund/data/fund_transaction.dart';
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
                  itemized: true,
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
  const _PeriodReportTab({
    required this.title,
    required this.start,
    this.itemized = true,
  });

  final String title;
  final DateTime start;

  /// Whether to show the itemized breakdown. Now defaults to true for both
  /// monthly and yearly reports to provide the "exact sense" of the data
  /// requested by the user.
  final bool itemized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Normalize end date to the end of the current day to stabilize the 
    // provider family key and prevent constant "loading" states.
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final transactions = ref.watch(
      ledgerTransactionsProvider((
        type: null,
        dateRange: DateTimeRange(start: start, end: endOfDay),
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

        final maxValue = [income, expenses, 1.0].reduce((a, b) => a > b ? a : b);

        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'No activity in $title yet',
          );
        }

        if (itemized) {
          final summary = ref.watch(fundSummaryProvider).value;
          // For monthly reports, we show the net change; for yearly/all-time
          // we might show the closing balance if available.
          final closing = summary?.availableBalance;
          
          return _ItemizedBreakdown(
            title: title,
            items: items,
            income: income,
            expenses: expenses,
            closing: closing,
            isYearly: start.month == 1 && start.day == 1 && (DateTime.now().year == start.year),
          );
        }

        // Fallback or simpler view if itemized was false (though we defaulted it to true)
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => context.colors.surfaceSunken,
                      tooltipBorder: BorderSide(color: context.colors.accentDark1),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = group.x == 0 ? 'Income' : 'Expenses';
                        return BarTooltipItem(
                          '$label\n',
                          TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.format(rod.toY),
                              style: TextStyle(
                                color: group.x == 0 
                                  ? context.financeColors.income 
                                  : context.financeColors.expense,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == meta.max) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              CurrencyFormatter.formatCompact(value),
                              style: TextStyle(color: context.colors.textQuaternary, fontSize: 9),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
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
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            value == 0 ? 'Income' : 'Expenses',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: context.colors.divider.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: context.financeColors.income,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: expenses,
                          color: context.financeColors.expense,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
              'Net for the period',
              CurrencyFormatter.format(income - expenses),
            ),
          ],
        );
      },
    );
  }
}

/// A unified itemized breakdown for any period (month or year).
class _ItemizedBreakdown extends StatelessWidget {
  const _ItemizedBreakdown({
    required this.title,
    required this.items,
    required this.income,
    required this.expenses,
    required this.closing,
    this.isYearly = false,
  });

  final String title;
  final List<FundTransaction> items;
  final double income;
  final double expenses;
  final double? closing;
  final bool isYearly;

  double _sumFor(TransactionType type) => items
      .where((t) => t.type == type)
      .fold<double>(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final net = income - expenses;
    
    // For a specific period, the "closing balance" from the summary is 
    // the current fund balance. The "opening balance" for this period 
    // is current - net.
    final closingValue = closing ?? net;
    final opening = closingValue - net;

    final moneyIn = <(String, double)>[
      ('Monthly contributions', _sumFor(TransactionType.monthlyContribution)),
      ('Special contributions', _sumFor(TransactionType.specialContribution)),
      ('Loan repayments', _sumFor(TransactionType.loanRepayment)),
      ('Interest received', _sumFor(TransactionType.interestPayment)),
      ('Other income', _sumFor(TransactionType.otherIncome) + _sumFor(TransactionType.refund)),
    ].where((e) => e.$2 > 0).toList();

    final moneyOut = <(String, double)>[
      ('Loans disbursed', _sumFor(TransactionType.loanDisbursement)),
      ('Fund expenses', _sumFor(TransactionType.fundExpense)),
      ('Other expenditure', _sumFor(TransactionType.otherExpenditure)),
    ].where((e) => e.$2 > 0).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          isYearly ? 'Yearly report $title' : 'Monthly report $title', 
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Hero summary card for the period
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.accentDark1.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERIOD NET',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(net),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: net >= 0 ? context.financeColors.income : context.financeColors.expense,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colors.divider,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CASH IN HAND',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(closingValue),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        if (moneyIn.isNotEmpty) ...[
          _BreakdownGroup(title: 'Money in', rows: moneyIn),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (moneyOut.isNotEmpty) ...[
          _BreakdownGroup(title: 'Money out', rows: moneyOut),
          const SizedBox(height: AppSpacing.lg),
        ],
        
        // Reconciliation Section
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reconciliation', 
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReportRow('Opening balance', CurrencyFormatter.format(opening)),
              _ReportRow('Plus income', '+${CurrencyFormatter.format(income)}'),
              _ReportRow('Less expenses', '−${CurrencyFormatter.format(expenses)}'),
              const Divider(height: AppSpacing.md),
              _ReportRow(
                'Closing balance', 
                CurrencyFormatter.format(closingValue),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownGroup extends StatelessWidget {
  const _BreakdownGroup({required this.title, required this.rows});
  final String title;
  final List<(String, double)> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.accent),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rows[i].$1),
                      Text(
                        CurrencyFormatter.format(rows[i].$2),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
    final colors = context.colors;
    final maxValue = months
        .map((m) => m.income)
        .fold<double>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.surfaceSunken,
              tooltipBorder: BorderSide(color: colors.accentDark1),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${DateFormatter.monthYear(months[groupIndex].month)}\n',
                  TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: CurrencyFormatter.format(rod.toY),
                      style: TextStyle(
                        color: context.financeColors.income,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      CurrencyFormatter.formatCompact(value),
                      style: TextStyle(color: colors.textQuaternary, fontSize: 9),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
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
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormatter.monthAbbr(months[index].month),
                      style: TextStyle(color: colors.textTertiary, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colors.divider.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          barGroups: [
            for (var i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: months[i].income,
                    color: Theme.of(context).colorScheme.primary,
                    width: 22,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
  const _ReportRow(this.label, this.value, {this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            value,
            style: isBold
                ? Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
