import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../fund/presentation/widgets/fund_hero_card.dart';
import '../../../fund/presentation/widgets/fund_summary_grid.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../../loans/providers/loans_providers.dart';
import '../../../members/providers/members_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §34 — admin dashboard: fund position + what needs the admin's
/// attention right now (pending members, pending loans).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(fundSummaryProvider);
    final members = ref.watch(allMembersProvider).value ?? const [];
    final pendingLoans =
        ref.watch(allLoansProvider(LoanStatus.requested)).value ?? const [];

    final pendingMembers = members.where((m) => !m.isApproved).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: const [AdminMoreMenu()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
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
                  label: 'Pending approvals',
                  value: '$pendingMembers',
                  icon: Icons.person_add_alt_outlined,
                  accentColor: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StatCard(
            label: 'Pending loan requests',
            value: '${pendingLoans.length}',
            icon: Icons.pending_actions_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          summary.when(
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
