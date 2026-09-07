import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/month_grid_heatmap.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../contributions/data/campaign.dart';
import '../../../contributions/providers/campaigns_providers.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../fund/presentation/widgets/fund_hero_card.dart';
import '../../../fund/presentation/widgets/fund_summary_grid.dart';
import '../../../fund/presentation/widgets/transaction_tile.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../../notifications/providers/notifications_providers.dart';
import '../widgets/contribution_share_card.dart';
import '../widgets/coverage_card.dart';
import '../widgets/fund_trend_card.dart';
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
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final trendMonths = ref.watch(monthlyFundGrowthProvider(12));
    final activeCampaigns = (ref.watch(campaignsProvider).value ?? const [])
        .where((c) => c.isActive)
        .toList();
    final activeCampaign = activeCampaigns.isEmpty ? null : activeCampaigns.first;
    final coverage = profile == null
        ? null
        : ref.watch(
            memberCoverageProvider((
              uid: profile.uid,
              memberSince: profile.memberSince,
            )),
          );
    final totalGiven = profile == null
        ? null
        : ref.watch(memberVerifiedContributionsTotalProvider(profile.uid));

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => context.go(RoutePaths.profile),
            child: InitialsAvatar(
              initials: profile?.initials ?? '?',
              imageUrl: profile?.photoUrl,
              radius: 16,
            ),
          ),
        ),
        title: Text(
          profile == null
              ? 'Overview'
              : 'Namaste, ${profile.fullName.split(' ').first}',
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
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
            summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(message: '$error'),
              data: (data) => Column(
                children: [
                  FundHeroCard(summary: data),
                  const SizedBox(height: AppSpacing.md),
                  FundSummaryGrid(summary: data),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.lg),
            if (activeCampaign != null) ...[
              _ActiveCampaignBanner(
                campaign: activeCampaign,
                extraCount: activeCampaigns.length - 1,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            switch (trendMonths) {
              AsyncData(:final value) when value.isNotEmpty => Column(
                children: [
                  FundTrendCard(months: value),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
            if (coverage != null)
              switch (coverage) {
                AsyncData(:final value) => Column(
                  children: [
                    CoverageCard(
                      coveredToLabel: value.coveredToLabel,
                      cells: value.currentYearCells,
                      onGive: () => context.push(RoutePaths.addContribution),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ContributionShareCard(
                      sharePaid: value.sharePaid,
                      totalGiven: totalGiven?.value ?? 0,
                      gapNote: switch (value.currentYearCells
                          .where((c) => c.state == MonthCellState.gap)
                          .map((c) => c.label)
                          .toList()) {
                        [] => null,
                        [final only] => '$only is the one gap.',
                        final gaps =>
                          '${gaps.join(', ')} are still open this year.',
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
                _ => const SizedBox.shrink(),
              },
            SectionHeader(
              title: 'Recent transactions',
              actionLabel: 'See all',
              onAction: () => context.push(RoutePaths.ledger),
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

/// The only other entry point to campaigns was a small AppBar icon on the
/// Give tab, easy to miss entirely — this puts the currently running
/// campaign in front of every member the moment they open the app.
class _ActiveCampaignBanner extends ConsumerWidget {
  const _ActiveCampaignBanner({required this.campaign, required this.extraCount});

  final Campaign campaign;
  final int extraCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raised = ref.watch(campaignProgressProvider(campaign.id)).value ?? 0;
    final target = campaign.targetAmount;
    final fraction = target == null || target == 0
        ? 0.0
        : (raised / target).clamp(0, 1).toDouble();

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () => context.push(RoutePaths.campaigns),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      extraCount > 0
                          ? '${campaign.name} +$extraCount more'
                          : campaign.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              if (target != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: fraction, minHeight: 6),
                ),
                const SizedBox(height: 6),
                Text(
                  '${CurrencyFormatter.format(raised)} raised of '
                  '${CurrencyFormatter.format(target)} target',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else
                Text(
                  '${CurrencyFormatter.format(raised)} raised so far',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
