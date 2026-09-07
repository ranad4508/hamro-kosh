import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/campaign.dart';
import '../../providers/campaigns_providers.dart';

/// SRS §15 — browse admin-created special-contribution campaigns and see
/// their progress toward a target, distinct from an ad-hoc special
/// contribution a member tags themselves.
class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Campaigns')),
      body: campaigns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No campaigns yet',
              message: 'Special contribution drives will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) =>
                CampaignCard(campaign: items[index]),
          );
        },
      ),
    );
  }
}

class CampaignCard extends ConsumerWidget {
  const CampaignCard({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(campaignProgressProvider(campaign.id));
    final scheme = Theme.of(context).colorScheme;

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
                    campaign.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (campaign.hasEnded)
                  Chip(
                    label: const Text('Ended'),
                    visualDensity: VisualDensity.compact,
                  )
                else if (campaign.isActive)
                  Chip(
                    label: const Text('Active'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              campaign.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${DateFormatter.shortDate(campaign.startDate)} – ${DateFormatter.shortDate(campaign.endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            switch (progress) {
              AsyncData(:final value) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: campaign.targetAmount > 0
                          ? (value / campaign.targetAmount).clamp(0, 1)
                          : 0,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${CurrencyFormatter.format(value)} of ${CurrencyFormatter.format(campaign.targetAmount)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              _ => const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            },
            if (!campaign.hasEnded) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                onPressed: () =>
                    context.push(RoutePaths.addContribution, extra: campaign),
                child: const Text('Contribute'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
