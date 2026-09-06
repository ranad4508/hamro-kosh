import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../contributions/data/contribution.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../fund/presentation/widgets/fund_summary_grid.dart';
import '../../../fund/presentation/widgets/transaction_tile.dart';
import '../../../fund/providers/fund_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §36, §38, §14 — fund overview, contribution verification queue, and
/// the expense/transaction ledger from the admin side.
class AdminFundScreen extends StatelessWidget {
  const AdminFundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Fund'),
          actions: const [AdminMoreMenu()],
          bottom: const TabBar(tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Verify contributions'),
            Tab(text: 'Ledger'),
          ]),
        ),
        body: const TabBarView(children: [
          _OverviewTab(),
          _VerifyContributionsTab(),
          _LedgerTab(),
        ]),
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
        children: [FundSummaryGrid(summary: data)],
      ),
    );
  }
}

class _VerifyContributionsTab extends ConsumerWidget {
  const _VerifyContributionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(allContributionsProvider(ContributionStatus.pending));

    return pending.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.task_alt,
            title: 'Nothing to verify',
            message: 'Pending contributions will show up here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _PendingContributionCard(item: items[index]),
        );
      },
    );
  }
}

class _PendingContributionCard extends ConsumerWidget {
  const _PendingContributionCard({required this.item});

  final Contribution item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(contributionsRepositoryProvider);

    Future<void> setStatus(ContributionStatus status) async {
      try {
        await repo.setStatus(
          memberUid: item.memberUid!,
          contributionId: item.id,
          status: status,
        );
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context,
            title: status == ContributionStatus.verified ? 'Verified' : 'Rejected',
            message: 'Contribution from ${item.memberName ?? 'member'} updated.',
          );
        }
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            title: 'Could not update',
            message: 'Something went wrong. Please try again.',
          );
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.memberName ?? 'Member', style: Theme.of(context).textTheme.titleSmall),
                StatusBadge(label: item.status.label, tone: item.status.tone),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${item.occasionName ?? DateFormatter.monthYear(item.date)} • ${CurrencyFormatter.format(item.amount)}'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setStatus(ContributionStatus.rejected),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setStatus(ContributionStatus.verified),
                    child: const Text('Verify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTab extends ConsumerWidget {
  const _LedgerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(fundTransactionsProvider(null));

    return transactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => TransactionTile(transaction: items[index]),
        );
      },
    );
  }
}
