import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../contributions/data/campaign.dart';
import '../../../contributions/presentation/screens/campaigns_screen.dart';
import '../../../contributions/providers/campaigns_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §15 — admin's campaign list, with a create action. Reuses
/// [CampaignCard] from the member-facing screen so progress/status render
/// identically in both places.
class AdminCampaignsScreen extends ConsumerWidget {
  const AdminCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        actions: const [AdminMoreMenu()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_campaigns_fab',
        onPressed: () => context.push(RoutePaths.adminCreateCampaign),
        icon: const Icon(Icons.add),
        label: const Text('New campaign'),
      ),
      body: campaigns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No campaigns yet',
              message: 'Create one to start a special contribution drive.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final campaign = items[index];
              return CampaignCard(
                campaign: campaign,
                trailing: _CampaignOptionsMenu(campaign: campaign),
              );
            },
          );
        },
      ),
    );
  }
}

class _CampaignOptionsMenu extends ConsumerWidget {
  const _CampaignOptionsMenu({required this.campaign});
  final Campaign campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(campaignsRepositoryProvider);
    final uid = ref.read(authStateProvider).value?.uid ?? '';

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'edit') {
          context.push(RoutePaths.adminEditCampaign, extra: campaign);
        } else if (value == 'publish') {
          await repo.setPublishedWithAudit(
            campaignId: campaign.id,
            campaignName: campaign.name,
            published: !campaign.isPublished,
            performedBy: uid,
          );
        } else if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Campaign?'),
              content: Text('Are you sure you want to delete "${campaign.name}"? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await repo.deleteCampaign(campaign.id);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'publish',
          child: Text(campaign.isPublished ? 'Unpublish' : 'Publish'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
