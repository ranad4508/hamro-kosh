import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/month_grid_heatmap.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../admin/data/privacy_settings.dart';
import '../../../admin/providers/admin_providers.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../loans/data/loan.dart';
import '../../../loans/providers/loans_providers.dart';
import '../../providers/members_providers.dart';

/// SRS §32 — a member's public financial profile. Total contributed, month
/// coverage, and active-loan status are computed live from the
/// `contributions`/`loans` collections (SRS §7/§12/§54's member-to-member
/// transparency), not read off a denormalized field on the user doc —
/// showing the same depth of detail the Members list and Home's own
/// coverage card give the member about themselves.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberDetailProvider(memberId));
    final totalContributed = ref.watch(
      memberVerifiedContributionsTotalProvider(memberId),
    );
    final privacy =
        ref.watch(privacySettingsProvider).value ?? PrivacySettings.defaults;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Member profile')),
      body: member.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Member not found',
            );
          }
          final coverage = ref.watch(
            memberCoverageProvider((uid: memberId, memberSince: data.memberSince)),
          );
          final loans = ref.watch(allLoansProvider(null)).value ?? const <Loan>[];
          final memberLoans = loans.where((l) => l.memberId == memberId).toList();
          final activeLoan = memberLoans
              .where((l) => l.countsTowardConcurrentCap)
              .toList()
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: data.photoUrl == null
                      ? null
                      : NetworkImage(data.photoUrl!),
                  child: data.photoUrl == null
                      ? Text(
                          data.fullName.isEmpty ? '?' : data.fullName[0],
                          style: Theme.of(context).textTheme.headlineMedium,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(data.fullName, style: Theme.of(context).textTheme.titleLarge),
                    if (data.role != UserRole.member) ...[
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: data.role == UserRole.superAdmin ? 'Super Admin' : 'Admin',
                        tone: StatusTone.info,
                      ),
                    ],
                  ],
                ),
              ),
              Center(
                child: Text(
                  'Member since ${DateFormatter.monthYear(data.memberSince)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (privacy.showPhoneNumber &&
                  data.phone != null &&
                  data.phone!.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Phone'),
                    trailing: Text(data.phone!),
                  ),
                ),
              if (privacy.showContributionAmounts) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _StatCell(
                      'Given',
                      switch (totalContributed) {
                        AsyncData(:final value) => CurrencyFormatter.format(value),
                        _ => '—',
                      },
                    ),
                    _StatCell(
                      'Covered to',
                      switch (coverage) {
                        AsyncData(:final value) => value.coveredToLabel ?? 'Not started',
                        _ => '—',
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                switch (coverage) {
                  AsyncData(:final value) => Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MonthGridHeatmap(cells: value.currentYearCells, columns: 6),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ],
              if (privacy.showActiveLoanStatus) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Loans', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                if (activeLoan == null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.request_quote_outlined),
                      title: const Text('Active loan'),
                      trailing: const Text('None'),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.request_quote_outlined),
                      title: Text(CurrencyFormatter.format(activeLoan.outstanding)),
                      subtitle: Text(
                        '${activeLoan.category.label(context)} · still to pay',
                      ),
                      trailing: StatusBadge(
                        label: activeLoan.status.label(context),
                        tone: activeLoan.status.tone,
                      ),
                    ),
                  ),
              ],
              if (!privacy.showContributionAmounts &&
                  !privacy.showActiveLoanStatus)
                const EmptyState(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Financial details are private',
                  message:
                      'The admin has hidden this information from other members.',
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: colors.textQuaternary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
