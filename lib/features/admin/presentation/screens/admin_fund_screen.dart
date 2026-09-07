import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/models/transaction_type.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bs_date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../contributions/data/contribution.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../fund/presentation/widgets/fund_hero_card.dart';
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
          actions: [
            IconButton(
              tooltip: 'Record a payment',
              icon: const Icon(Icons.point_of_sale_outlined),
              onPressed: () => context.push(RoutePaths.adminRecordContribution),
            ),
            const AdminMoreMenu(),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Verify contributions'),
              Tab(text: 'Ledger'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_OverviewTab(), _VerifyContributionsTab(), _LedgerTab()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'admin_fund_fab',
          onPressed: () => context.push(RoutePaths.adminRecordExpense),
          icon: const Icon(Icons.remove_circle_outline),
          label: const Text('Record expense'),
        ),
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
        children: [
          FundHeroCard(summary: data),
          const SizedBox(height: AppSpacing.md),
          FundSummaryGrid(summary: data),
        ],
      ),
    );
  }
}

class _VerifyContributionsTab extends ConsumerWidget {
  const _VerifyContributionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      allContributionsProvider(ContributionStatus.pending),
    );
    final colors = context.colors;

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
        final total = items.fold<double>(0, (s, c) => s + c.amount);
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '${items.length} waiting · ${CurrencyFormatter.format(total)}',
                  style: TextStyle(fontSize: 12.5, color: colors.textTertiary),
                ),
              );
            }
            return _PendingContributionCard(item: items[index - 1]);
          },
        );
      },
    );
  }
}

/// One BS month + the amount claimed for it, distributing a multi-month
/// payment's total evenly across the months it covers so an admin can see
/// "which months this settles" at a glance (`design_spec.md` §3c).
List<({String label, double amount})> _claimedMonths(Contribution item) {
  if (item.category != ContributionCategory.monthly) return const [];
  final start = item.date.toNepaliDateTime();
  final perMonth = item.amount / item.monthsCovered;
  var m = start.month;
  final result = <({String label, double amount})>[];
  for (var i = 0; i < item.monthsCovered; i++) {
    result.add((
      label: BsDateFormatter.monthNames[m - 1],
      amount: perMonth,
    ));
    m++;
    if (m > 12) m = 1;
  }
  return result;
}

class _PendingContributionCard extends ConsumerStatefulWidget {
  const _PendingContributionCard({required this.item});

  final Contribution item;

  @override
  ConsumerState<_PendingContributionCard> createState() =>
      _PendingContributionCardState();
}

class _PendingContributionCardState
    extends ConsumerState<_PendingContributionCard> {
  bool _busy = false;

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send it back'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Why? (e.g. screenshot unclear, amount differs)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(reasonController.text.trim()),
            child: const Text('Send back'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    await _setStatus(ContributionStatus.rejected, reason: reason);
  }

  Future<void> _setStatus(ContributionStatus status, {String? reason}) async {
    // Without this guard, a slow network round-trip plus an impatient
    // second tap on Verify/Query fired the Cloud Function twice — this was
    // recording the same contribution in the ledger two times over.
    if (_busy) return;
    setState(() => _busy = true);
    final cloudFunctions = ref.read(cloudFunctionsServiceProvider);
    try {
      // Goes through a Cloud Function rather than a direct Firestore
      // write: verifying a contribution also has to record a ledger
      // entry, update the fund total, and (via the notifyOnTransaction
      // trigger) broadcast the transparency email (SRS §12/§41/§54) —
      // side effects a client write can't safely trigger on its own.
      await cloudFunctions.verifyContribution(
        memberUid: widget.item.memberUid!,
        contributionId: widget.item.id,
        approve: status == ContributionStatus.verified,
        reason: reason,
      );
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          title: status == ContributionStatus.verified ? 'Verified' : 'Sent back',
          message: 'Contribution from ${widget.item.memberName ?? 'member'} updated.',
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, title: 'Could not update', message: e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = context.colors;
    final months = _claimedMonths(item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.memberName ?? 'Member',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${item.paymentMethod ?? 'Unknown method'} · '
                      '${DateFormatter.relative(item.date)}'
                      '${item.reference != null ? ' · ${item.reference}' : ''}',
                      style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(item.amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          if (item.proofUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => showFullScreenImage(context, item.proofUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.proofUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.bg.withValues(alpha: 0.55),
                      child: const Text(
                        'Tap to open',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.5, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (months.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Asked to cover:',
              style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in months)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.accentDark2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${m.label} ${m.amount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: colors.accentLight),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  child: const Text('Query'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _setStatus(ContributionStatus.verified),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify and record'),
                ),
              ),
            ],
          ),
        ],
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
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return TransactionTile(
              transaction: item,
              // A correction can't itself be corrected — see
              // correctTransaction in functions/index.js.
              onCorrect: item.type == TransactionType.adjustment
                  ? null
                  : () => context.push(
                      RoutePaths.adminCorrectTransaction,
                      extra: item,
                    ),
            );
          },
        );
      },
    );
  }
}
