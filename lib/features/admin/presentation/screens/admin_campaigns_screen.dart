import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
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
            itemBuilder: (context, index) =>
                CampaignCard(campaign: items[index]),
          );
        },
      ),
    );
  }
}
