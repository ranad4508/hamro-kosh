import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../disputes/data/dispute.dart';
import '../../../disputes/providers/disputes_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS "Dispute handling" — admin reviews member-raised issues and resolves
/// them with an optional response.
class AdminDisputesScreen extends ConsumerWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(allDisputesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disputes'),
        actions: const [AdminMoreMenu()],
      ),
      body: disputes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.report_problem_outlined,
              title: 'No disputes reported',
            );
          }
          final open = items
              .where((d) => d.status == DisputeStatus.open)
              .toList();
          final resolved = items
              .where((d) => d.status == DisputeStatus.resolved)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (open.isNotEmpty) ...[
                Text('Open', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                for (final d in open) _AdminDisputeCard(dispute: d),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (resolved.isNotEmpty) ...[
                Text('Resolved', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                for (final d in resolved) _AdminDisputeCard(dispute: d),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AdminDisputeCard extends ConsumerWidget {
  const _AdminDisputeCard({required this.dispute});

  final Dispute dispute;

  void _showResolveSheet(BuildContext context, WidgetRef ref) {
    final response = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resolve report',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Response to the member (optional)',
              controller: response,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Mark resolved',
              onPressed: () async {
                try {
                  await ref
                      .read(disputesRepositoryProvider)
                      .resolve(
                        disputeId: dispute.id,
                        subject: dispute.subject,
                        performedBy: ref.read(authStateProvider).value?.uid ?? '',
                        adminResponse: response.text.trim().isEmpty
                            ? null
                            : response.text.trim(),
                      );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  if (context.mounted) {
                    AppSnackbar.showSuccess(
                      context,
                      title: 'Resolved',
                      message: dispute.subject,
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    AppSnackbar.showError(
                      context,
                      title: 'Could not resolve',
                      message: 'Something went wrong. Please try again.',
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  label: dispute.status.label(context),
                  tone: dispute.status.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${dispute.memberName ?? 'Member'} • ${DateFormatter.shortDate(dispute.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(dispute.description),
            if (dispute.status == DisputeStatus.open) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => _showResolveSheet(context, ref),
                  child: const Text('Resolve'),
                ),
              ),
            ] else if (dispute.adminResponse != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Response: ${dispute.adminResponse}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
