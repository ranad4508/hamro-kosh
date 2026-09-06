import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/models/contribution_type.dart';
import '../../data/contribution.dart';
import '../../providers/contributions_providers.dart';

/// SRS §7-§10 — monthly + special contributions and full history, with
/// year/type filtering for the history tab.
class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contributions'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Monthly'),
            Tab(text: 'Special'),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(RoutePaths.addContribution),
          icon: const Icon(Icons.add),
          label: const Text('Add contribution'),
        ),
        body: const TabBarView(children: [
          _ContributionsList(category: ContributionCategory.monthly),
          _ContributionsList(category: ContributionCategory.special),
        ]),
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
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _ContributionTile(item: items[index]),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.occasionName ?? DateFormatter.monthYear(item.date)),
      subtitle: Text(DateFormatter.shortDate(item.date)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(CurrencyFormatter.format(item.amount)),
          const SizedBox(height: 4),
          StatusBadge(label: item.status.label, tone: item.status.tone),
        ],
      ),
    );
  }
}
