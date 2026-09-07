import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../loans/data/loan.dart';
import '../../../loans/data/loan_repayment.dart';
import '../../../loans/presentation/widgets/loan_card.dart';
import '../../../loans/presentation/widgets/loan_cost_timeline.dart';
import '../../../loans/providers/loans_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §17-§19, §37 — review requests, approve at the loan's fixed category
/// rate/terms, or reject. The interest rate itself is never admin-chosen
/// (SRS.md's fixed lending policy): only the repayment window for an
/// emergency loan (1 or 2 quarters) is a choice made here.
class AdminLoansScreen extends StatelessWidget {
  const AdminLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Loans'),
          actions: const [AdminMoreMenu()],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Active'),
              Tab(text: 'Repayments'),
              Tab(text: 'Closed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LoanStatusList(
              statuses: [LoanStatus.requested, LoanStatus.underReview],
            ),
            _LoanStatusList(
              statuses: [
                LoanStatus.approved,
                LoanStatus.active,
                LoanStatus.overdue,
                LoanStatus.partiallyPaid,
              ],
            ),
            _PendingRepaymentsTab(),
            _LoanStatusList(
              statuses: [
                LoanStatus.completed,
                LoanStatus.rejected,
                LoanStatus.cancelled,
                LoanStatus.defaulted,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanStatusList extends ConsumerWidget {
  const _LoanStatusList({required this.statuses});

  final List<LoanStatus> statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Each status has its own stream provider entry; merge the ones this
    // tab cares about client-side rather than firing an `in` server query
    // per tab (keeps the admin loans list simple to reason about).
    final results = statuses
        .map((s) => ref.watch(allLoansProvider(s)))
        .toList();

    if (results.any((r) => r.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = results.firstWhere(
      (r) => r.hasError,
      orElse: () => results.first,
    );
    if (error.hasError) {
      return AppErrorState(message: '${error.error}');
    }

    final loans = results.expand((r) => r.value ?? const <Loan>[]).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    if (loans.isEmpty) {
      return const EmptyState(
        icon: Icons.request_quote_outlined,
        title: 'Nothing here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: loans.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return LoanCard(
          loan: loan,
          onTap:
              loan.status == LoanStatus.requested ||
                  loan.status == LoanStatus.underReview
              ? () => _showReviewSheet(context, ref, loan)
              : null,
        );
      },
    );
  }

  void _showReviewSheet(BuildContext screenContext, WidgetRef ref, Loan loan) {
    final cloudFunctions = ref.read(cloudFunctionsServiceProvider);
    final allowedMonths = loan.category.allowedRepaymentMonths;
    final monthsNotifier = ValueNotifier<int>(allowedMonths.first);

    // Both actions go through a Cloud Function rather than a direct
    // Firestore write: approving a loan also has to record the ledger
    // entry, update the fund total, and (via the notifyOnTransaction
    // trigger) broadcast the transparency email (SRS §12/§41/§54) — see
    // functions/index.js. The interest rate is never sent from here: it's
    // fixed by `loan.category` and computed server-side.
    Future<void> reject(BuildContext sheetContext) async {
      try {
        await cloudFunctions.rejectLoan(loan.id);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        if (screenContext.mounted) {
          AppSnackbar.showInfo(
            screenContext,
            title: 'Loan rejected',
            message: loan.purpose,
          );
        }
      } on CloudFunctionsApiException catch (e) {
        if (screenContext.mounted) {
          AppSnackbar.showError(
            screenContext,
            title: 'Could not reject loan',
            message: e.message,
          );
        }
      }
    }

    Future<void> approve(BuildContext sheetContext) async {
      try {
        await cloudFunctions.approveLoan(
          loanId: loan.id,
          repaymentMonths: monthsNotifier.value,
        );
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        if (screenContext.mounted) {
          AppSnackbar.showSuccess(
            screenContext,
            title: 'Loan approved',
            message:
                'Repayment schedule set for ${loan.borrowerName ?? 'the borrower'}.',
          );
        }
      } on CloudFunctionsApiException catch (e) {
        if (screenContext.mounted) {
          AppSnackbar.showError(
            screenContext,
            title: 'Could not approve loan',
            message: e.message,
          );
        }
      }
    }

    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review loan request',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${loan.category.label} loan · ${CurrencyFormatter.format(loan.amount)} · '
                '${loan.category.monthlyInterestRatePercent}% / month',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loan.category.description,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              if (allowedMonths.length > 1) ...[
                Text(
                  'Repayment period',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                ValueListenableBuilder<int>(
                  valueListenable: monthsNotifier,
                  builder: (context, months, _) => SegmentedButton<int>(
                    segments: allowedMonths
                        .map(
                          (m) =>
                              ButtonSegment(value: m, label: Text('$m months')),
                        )
                        .toList(),
                    selected: {months},
                    onSelectionChanged: (selection) =>
                        monthsNotifier.value = selection.first,
                  ),
                ),
              ] else
                Text(
                  'Repayment period: ${allowedMonths.first} months',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<int>(
                valueListenable: monthsNotifier,
                builder: (context, months, _) => LoanCostTimeline(
                  principal: loan.amount,
                  category: loan.category,
                  dueMonths: months,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => reject(sheetContext),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Approve',
                      onPressed: () => approve(sheetContext),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingRepaymentsTab extends ConsumerWidget {
  const _PendingRepaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repayments = ref.watch(pendingRepaymentsProvider);

    return repayments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.task_alt,
            title: 'Nothing to verify',
            message: 'Pending repayments will show up here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) =>
              _PendingRepaymentCard(item: items[index]),
        );
      },
    );
  }
}

class _PendingRepaymentCard extends ConsumerWidget {
  const _PendingRepaymentCard({required this.item});

  final LoanRepayment item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloudFunctions = ref.read(cloudFunctionsServiceProvider);
    final loan = ref.watch(loanDetailProvider(item.loanId)).value;

    Future<void> setStatus(bool approve) async {
      try {
        await cloudFunctions.verifyRepayment(
          repaymentId: item.id,
          approve: approve,
        );
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context,
            title: approve ? 'Repayment verified' : 'Repayment rejected',
            message: '${item.borrowerName ?? 'Member'}\'s repayment updated.',
          );
        }
      } on CloudFunctionsApiException catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            title: 'Could not update',
            message: e.message,
          );
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.borrowerName ?? 'Member',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                StatusBadge(label: item.status.label, tone: item.status.tone),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${CurrencyFormatter.format(item.amount)} • ${DateFormatter.shortDate(item.date)}'
              '${item.paymentMethod != null ? ' • ${item.paymentMethod}' : ''}'
              '${loan != null ? ' • outstanding ${CurrencyFormatter.format(loan.outstanding)}' : ''}',
            ),
            if (loan != null && item.amount > loan.outstanding + 0.01) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This exceeds the loan\'s current outstanding balance — verifying it will fail '
                'server-side unless the balance changes first.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (item.proofUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.proofUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setStatus(false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setStatus(true),
                    child: const Text('Verify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
