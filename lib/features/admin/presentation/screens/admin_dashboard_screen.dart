import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/finance_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../fund/presentation/widgets/fund_hero_card.dart';
import '../../../fund/presentation/widgets/fund_summary_grid.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../../loans/providers/loans_providers.dart';
import '../../../members/providers/members_providers.dart';
import '../widgets/admin_more_menu.dart';

/// The admin app's home question is "what is waiting on me", not the
/// balance (`design_spec.md` §3, screen `3a`) — a "waiting on you" card
/// leads, with the fund position underneath for reference. There is no
/// membership-approval queue here: self-registration and admin-provisioned
/// accounts are both immediately active, so the only things ever waiting
/// on an admin are loan requests and payments to verify.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(fundSummaryProvider);
    final summary = summaryAsync.value;
    final members = ref.watch(allMembersProvider).value ?? const [];
    final outstandingLoanCount =
        ref.watch(outstandingLoanCountProvider).value ?? 0;
    final pendingLoans =
        ref.watch(allLoansProvider(LoanStatus.requested)).value ?? const [];
    final pendingContributions =
        ref.watch(allContributionsProvider(ContributionStatus.pending)).value ??
        const [];

    final pendingContributionsTotal = pendingContributions.fold<double>(
      0,
      (total, c) => total + c.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: const [AdminMoreMenu()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.accentDark1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WAITING ON YOU',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 10),
                if (pendingLoans.isEmpty && pendingContributions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Nothing waiting — you're all caught up.",
                      style: TextStyle(color: context.colors.textTertiary),
                    ),
                  ),
                if (pendingLoans.isNotEmpty)
                  _WaitingRow(
                    icon: Icons.request_quote_outlined,
                    title:
                        '${pendingLoans.length} loan request${pendingLoans.length == 1 ? '' : 's'}',
                    subtitle: CurrencyFormatter.format(
                      pendingLoans.fold(0.0, (t, l) => t + l.amount),
                    ),
                    onTap: () => context.go(RoutePaths.adminLoans),
                  ),
                if (pendingContributions.isNotEmpty)
                  _WaitingRow(
                    icon: Icons.receipt_long_outlined,
                    title:
                        '${pendingContributions.length} payment${pendingContributions.length == 1 ? '' : 's'} to verify',
                    subtitle: CurrencyFormatter.format(pendingContributionsTotal),
                    onTap: () => context.go(RoutePaths.adminFund),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // IntrinsicHeight + a stretched Row is what actually forces both
          // cards to match the taller one's height — a Row's default
          // crossAxisAlignment only centers children within whatever height
          // each already wants, so a longer label wrapping to a second line
          // (as "Loans outstanding" does more readily than "Total members")
          // would otherwise leave the two cards visibly uneven.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total members',
                    value: '${members.length}',
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatCard(
                    label: 'Loans outstanding',
                    value: '$outstandingLoanCount',
                    icon: Icons.pending_actions_outlined,
                    accentColor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StatCard(
            label: 'Total contributions',
            value: CurrencyFormatter.format(
              (summary?.totalContributions ?? 0) +
                  (summary?.totalSpecialContributions ?? 0),
            ),
            icon: Icons.volunteer_activism,
            accentColor: context.financeColors.income,
          ),
          const SizedBox(height: AppSpacing.lg),
          summaryAsync.when(
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
        ],
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 19, color: colors.accentLight),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }
}
