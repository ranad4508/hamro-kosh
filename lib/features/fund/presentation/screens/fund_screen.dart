import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/finance_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/fund_providers.dart';
import '../widgets/fund_hero_card.dart';
import '../widgets/fund_summary_grid.dart';
import '../widgets/transaction_tile.dart';

/// SRS §6/§41 — Fund overview + Money In / Money Out / Usage tabs, with a
/// link out to the full filterable ledger (§11-13).
class FundScreen extends StatelessWidget {
  const FundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Fund'),
          actions: [
            IconButton(
              tooltip: 'Full ledger',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => context.push(RoutePaths.transactions),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Money In'),
              Tab(text: 'Money Out'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _FlowTab(inflow: true),
            _FlowTab(inflow: false),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(fundSummaryProvider);

    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (data) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FundHeroCard(summary: data),
          const SizedBox(height: AppSpacing.md),
          FundSummaryGrid(summary: data),
        ],
      ),
    );
  }
}

class _FlowTab extends ConsumerWidget {
  const _FlowTab({required this.inflow});

  final bool inflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(fundTransactionsProvider(null));

    return transactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (all) {
        final filtered = all.where((t) => t.type.isInflow == inflow).toList();
        if (filtered.isEmpty) {
          return EmptyState(
            icon: inflow ? Icons.call_received : Icons.call_made,
            title: inflow
                ? 'No income recorded yet'
                : 'No expenses recorded yet',
          );
        }
        final total = filtered.fold<double>(0, (sum, t) => sum + t.amount);
        final finance = context.financeColors;
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: filtered.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      inflow ? 'Total in' : 'Total out',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      CurrencyFormatter.format(total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: inflow ? finance.income : finance.expense,
                      ),
                    ),
                  ],
                ),
              );
            }
            return TransactionTile(transaction: filtered[index - 1]);
          },
        );
      },
    );
  }
}
