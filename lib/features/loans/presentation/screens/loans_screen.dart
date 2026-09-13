import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../data/loan.dart';
import '../../providers/loans_providers.dart';

/// SRS §15-§25 — the member's own active loan front and center
/// (`design_spec.md` §2g), plus the fund-wide transparency list of where
/// every member's money is currently lent.
///
/// Deliberately built on two *independent* providers rather than nesting
/// everything inside one `.when()`: [myLoansProvider] (this member's own
/// loans — small, fast, always needed) drives the header, the pending/
/// active loan cards, and the request button, while [allLoansProvider]
/// (fund-wide, used only for the transparency list at the bottom) is
/// watched separately. Nesting the whole screen inside the fund-wide
/// query's `.when()` meant a slow or stuck fund-wide listen blanked out
/// even "Request a new loan" — a member's own basic loan actions
/// shouldn't depend on a community-wide query succeeding first.
class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myLoansAsync = ref.watch(myLoansProvider);
    final allLoansAsync = ref.watch(allLoansProvider(null));
    final colors = context.colors;

    final myLoans = myLoansAsync.value ?? const <Loan>[];
    final myActiveLoan = myLoans
        .where((l) => l.countsTowardConcurrentCap)
        .firstOrNull;
    // A loan sits at `requested`/`underReview` until an admin approves it —
    // `countsTowardConcurrentCap` deliberately excludes that stage, so
    // without this it was invisible anywhere on this screen from the
    // moment you asked for it until the moment it was approved.
    final myPendingLoan = myLoans
        .where(
          (l) =>
              l.status == LoanStatus.requested ||
              l.status == LoanStatus.underReview,
        )
        .firstOrNull;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'loans_fab',
        onPressed: () => context.push(RoutePaths.loanRequest),
        icon: const Icon(Icons.add),
        label: const Text('Request loan'),
      ),
      body: SafeArea(
        child: myLoansAsync.isLoading && myLoans.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  Text('Loans', style: Theme.of(context).textTheme.headlineSmall),
                  switch (allLoansAsync) {
                    AsyncData(:final value) => Text(
                      '${CurrencyFormatter.format(value.where((l) => l.countsTowardConcurrentCap).fold(0.0, (s, l) => s + l.outstanding))} '
                      "out with ${value.where((l) => l.countsTowardConcurrentCap).map((l) => l.borrowerName).toSet().length} members",
                      style: TextStyle(fontSize: 12.5, color: colors.textTertiary),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                  const SizedBox(height: AppSpacing.lg),
                  if (myPendingLoan != null) ...[
                    _PendingLoanCard(
                      loan: myPendingLoan,
                      onTap: () => context
                          .push(RoutePaths.loanDetail(myPendingLoan.id)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (myActiveLoan != null) ...[
                    _MyLoanHeroCard(loan: myActiveLoan),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AppButton(
                    label: 'Request a new loan',
                    onPressed: () => context.push(RoutePaths.loanRequest),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Personal loans go up to 30% of the fund balance, '
                    'Emergency up to 80% — see the exact figures on the '
                    'request screen.',
                    style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    "Where the group's money is lent",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  switch (allLoansAsync) {
                    AsyncLoading() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    AsyncError(:final error) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        "Couldn't load this right now: $error",
                        style: TextStyle(fontSize: 12, color: colors.textQuaternary),
                      ),
                    ),
                    AsyncData(:final value) => _LenderList(
                      outstanding: value
                          .where((l) => l.countsTowardConcurrentCap)
                          .toList(),
                      myActiveLoanId: myActiveLoan?.id,
                    ),
                  },
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Amounts and repayment status are open to every member. '
                    'What the money was for is not.',
                    style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LenderList extends StatelessWidget {
  const _LenderList({required this.outstanding, required this.myActiveLoanId});

  final List<Loan> outstanding;
  final String? myActiveLoanId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (outstanding.isEmpty) {
      return const EmptyState(
        icon: Icons.request_quote_outlined,
        title: 'No loans outstanding right now',
      );
    }
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < outstanding.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.divider),
            _LenderRow(
              loan: outstanding[i],
              isYou: outstanding[i].id == myActiveLoanId,
              onTap: () =>
                  context.push(RoutePaths.loanDetail(outstanding[i].id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MyLoanHeroCard extends StatelessWidget {
  const _MyLoanHeroCard({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalPayable = loan.currentTotalPayable;
    final fraction = totalPayable == 0
        ? 0.0
        : (loan.amountPaid / totalPayable).clamp(0, 1).toDouble();
    final isLate =
        loan.status == LoanStatus.overdue ||
        (loan.nextDueDate != null && loan.nextDueDate!.isBefore(DateTime.now()));
    // The per-period installment is the fixed schedule agreed at approval,
    // not the live, ever-growing `currentTotalPayable` — a repayment plan
    // shouldn't silently inflate just because a prior installment is late;
    // that lateness shows up as penalty in "outstanding" instead.
    final scheduledTotalPayable = loan.totalPayable ?? loan.amount;
    final instalment = loan.repaymentMonths == null || loan.repaymentMonths == 0
        ? null
        : scheduledTotalPayable / loan.repaymentMonths!;
    final instalmentsPaid = instalment == null || instalment == 0
        ? 0
        : (loan.amountPaid / instalment).floor();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentDark1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR LOAN',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w500,
                  color: colors.accent,
                ),
              ),
              _StatusTag(isLate: isLate),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(loan.outstanding),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'still to pay',
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: colors.surfaceSunken,
              color: isLate ? colors.warning : colors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(loan.amountPaid)} of '
                '${CurrencyFormatter.format(totalPayable)} payable',
                style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
              ),
              if (loan.repaymentMonths != null)
                Text(
                  '$instalmentsPaid of ${loan.repaymentMonths} instalments',
                  style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
                ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              _DetailCell('Principal', CurrencyFormatter.format(loan.amount)),
              _DetailCell(
                'Interest',
                '${loan.interestRatePercent ?? loan.category.monthlyInterestRatePercent}%/yr',
              ),
              const _DetailCell('Method', 'Reducing'),
            ],
          ),
          if (loan.nextDueDate != null && instalment != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.neutralRing),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next instalment ${CurrencyFormatter.format(instalment)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Due ${DateFormatter.shortDate(loan.nextDueDate!)}',
                          style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 40),
                    ),
                    onPressed: () =>
                        context.push(RoutePaths.loanRepay(loan.id)),
                    child: const Text('Repay'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingLoanCard extends StatelessWidget {
  const _PendingLoanCard({required this.loan, required this.onTap});
  final Loan loan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final daysWaiting = DateTime.now().difference(loan.requestedAt).inDays;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.hourglass_top_outlined, color: colors.accentLight),
        title: Text('${loan.category.label(context)} loan requested'),
        subtitle: Text(
          '${CurrencyFormatter.format(loan.amount)} · '
          'waiting $daysWaiting day${daysWaiting == 1 ? '' : 's'} for admin review',
          style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.textQuaternary),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.isLate});
  final bool isLate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLate ? colors.warningSurface : colors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLate ? 'Late' : 'On track',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isLate ? colors.warning : colors.bg,
        ),
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: colors.textQuaternary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _LenderRow extends StatelessWidget {
  const _LenderRow({required this.loan, required this.isYou, this.onTap});
  final Loan loan;
  final bool isYou;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLate =
        loan.status == LoanStatus.overdue ||
        (loan.nextDueDate != null && loan.nextDueDate!.isBefore(DateTime.now()));
    final daysLate = loan.nextDueDate == null
        ? 0
        : DateTime.now().difference(loan.nextDueDate!).inDays;
    final name = isYou ? 'You' : (loan.borrowerName ?? 'Member');

    return ListTile(
      leading: InitialsAvatar.fromName(name),
      title: Text(name),
      subtitle: Text(
        '${CurrencyFormatter.format(loan.amount)} · '
        '${loan.repaymentMonths ?? '—'} months · '
        'since ${loan.disbursedAt == null ? '—' : DateFormatter.monthYear(loan.disbursedAt!)}',
        style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(loan.outstanding),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            isLate && daysLate > 0 ? '$daysLate days late' : 'on track',
            style: TextStyle(
              fontSize: 11,
              color: isLate && daysLate > 0 ? colors.warning : colors.accentLight,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
