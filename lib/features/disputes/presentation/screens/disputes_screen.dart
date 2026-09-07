import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/dispute.dart';
import '../../providers/disputes_providers.dart';

/// SRS "Report transaction issues" — a member's own submitted reports.
class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(myDisputesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My reports')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.reportIssue),
        icon: const Icon(Icons.add),
        label: const Text('Report an issue'),
      ),
      body: disputes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.report_problem_outlined,
              title: 'No reports yet',
              message:
                  'Something look wrong with a transaction? Report it here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _DisputeCard(dispute: items[index]),
          );
        },
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({required this.dispute});

  final Dispute dispute;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dispute.subject,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                StatusBadge(
                  label: dispute.status.label,
                  tone: dispute.status.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(dispute.description),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormatter.shortDate(dispute.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (dispute.adminResponse != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin response',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(dispute.adminResponse!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
