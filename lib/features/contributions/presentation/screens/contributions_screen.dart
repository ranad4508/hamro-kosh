import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../../core/models/loan_status.dart';
import '../../data/contribution.dart';
import '../../providers/contributions_providers.dart';
import '../widgets/my_record_tab.dart';

/// SRS §7-§10 — the member's own contribution record
/// (`design_spec.md` §2f "My record"), plus the Monthly/Special breakdown
/// lists.
class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contributions'),
          actions: [
            IconButton(
              tooltip: 'Campaigns',
              icon: const Icon(Icons.campaign_outlined),
              onPressed: () => context.push(RoutePaths.campaigns),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My record'),
              Tab(text: 'Monthly'),
              Tab(text: 'Special'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'contributions_fab',
          onPressed: () => context.push(RoutePaths.addContribution),
          icon: const Icon(Icons.add),
          label: const Text('Add contribution'),
        ),
        body: const TabBarView(
          children: [
            MyRecordTab(),
            _ContributionsList(category: ContributionCategory.monthly),
            _ContributionsList(category: ContributionCategory.special),
          ],
        ),
      ),
    );
  }
}

class _ContributionsList extends ConsumerWidget {
  const _ContributionsList({required this.category});

  final ContributionCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(myContributionsProvider);

    return contributions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (all) {
        final items = all.where((c) => c.category == category).toList();
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.volunteer_activism_outlined,
            title: category == ContributionCategory.monthly
                ? 'No monthly contributions yet'
                : 'No special contributions yet',
          );
        }

        final verifiedTotal = items
            .where((c) => c.status == ContributionStatus.verified)
            .fold<double>(0, (sum, c) => sum + c.amount);
        final pendingCount = items
            .where((c) => c.status == ContributionStatus.pending)
            .length;

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verified total',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(verifiedTotal),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (pendingCount > 0)
                          Text(
                            '$pendingCount pending verification',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }
            return _ContributionTile(item: items[index - 1]);
          },
        );
      },
    );
  }
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({required this.item});

  final Contribution item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: item.proofUrl == null
          ? null
          : () => showFullScreenImage(context, item.proofUrl!),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.category == ContributionCategory.monthly
              ? Icons.calendar_month
              : Icons.celebration,
          size: 20,
          color: scheme.onSecondaryContainer,
        ),
      ),
      title: Text(item.occasionName ?? item.coveredMonthsLabel),
      subtitle: Row(
        children: [
          Text(DateFormatter.shortDate(item.date)),
          if (item.monthsCovered > 1) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.history_toggle_off,
              size: 13,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 2),
            Text(
              '${item.monthsCovered} months',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (item.proofUrl != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.attachment, size: 13, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(CurrencyFormatter.format(item.amount)),
          const SizedBox(height: 4),
          StatusBadge(label: item.status.label(context), tone: item.status.tone),
        ],
      ),
    );
  }
}
