import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../fund/presentation/widgets/fund_summary_grid.dart';
import '../../../fund/presentation/widgets/transaction_tile.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../../notifications/providers/notifications_providers.dart';
import '../widgets/quick_actions_row.dart';

/// SRS §5, §54 — "the member should not need to ask the administrator for
/// these basic financial details." This is the first screen after login.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final summary = ref.watch(fundSummaryProvider);
    final recentTransactions = ref.watch(fundTransactionsProvider(null));
    final announcements = ref.watch(announcementsProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profile == null ? 'Overview' : 'Namaste, ${profile.fullName.split(' ').first}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RoutePaths.notifications),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fundSummaryProvider);
          ref.invalidate(fundTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (announcements != null && announcements.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(announcements.first.title),
                  subtitle: Text(
                    announcements.first.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => context.push(RoutePaths.notifications),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.lg),
            summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(message: '$error'),
              data: (data) => FundSummaryGrid(summary: data),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: 'Recent transactions',
              actionLabel: 'See all',
              onAction: () => context.push(RoutePaths.transactions),
            ),
            const SizedBox(height: AppSpacing.sm),
            recentTransactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(message: '$error'),
              data: (items) {
                final preview = items.take(5).toList();
                if (preview.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 40 * i),
                        child: TransactionTile(transaction: preview[i]),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
