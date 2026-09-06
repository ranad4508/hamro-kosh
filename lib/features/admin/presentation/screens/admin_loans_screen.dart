import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../loans/data/loan.dart';
import '../../../loans/presentation/widgets/loan_card.dart';
import '../../../loans/providers/loans_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §17-§18, §37 — review requests, approve with interest/repayment
/// terms, or reject.
class AdminLoansScreen extends StatelessWidget {
  const AdminLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Loans'),
          actions: const [AdminMoreMenu()],
          bottom: const TabBar(tabs: [
            Tab(text: 'Requests'),
            Tab(text: 'Active'),
            Tab(text: 'Closed'),
          ]),
        ),
        body: const TabBarView(children: [
          _LoanStatusList(statuses: [LoanStatus.requested, LoanStatus.underReview]),
          _LoanStatusList(statuses: [LoanStatus.approved, LoanStatus.active, LoanStatus.overdue, LoanStatus.partiallyPaid]),
          _LoanStatusList(statuses: [LoanStatus.completed, LoanStatus.rejected, LoanStatus.cancelled, LoanStatus.defaulted]),
        ]),
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
    final results = statuses.map((s) => ref.watch(allLoansProvider(s))).toList();

    if (results.any((r) => r.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = results.firstWhere((r) => r.hasError, orElse: () => results.first);
    if (error.hasError) {
      return AppErrorState(message: '${error.error}');
    }

    final loans = results.expand((r) => r.value ?? const <Loan>[]).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    if (loans.isEmpty) {
      return const EmptyState(icon: Icons.request_quote_outlined, title: 'Nothing here');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: loans.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return LoanCard(
          loan: loan,
          onTap: loan.status == LoanStatus.requested || loan.status == LoanStatus.underReview
              ? () => _showReviewSheet(context, ref, loan)
              : null,
        );
      },
    );
  }

  void _showReviewSheet(BuildContext screenContext, WidgetRef ref, Loan loan) {
    final rateController = TextEditingController(text: '12');
    final monthsController =
        TextEditingController(text: '${loan.repaymentMonths ?? 6}');

    Future<void> reject(BuildContext sheetContext) async {
      try {
        await ref.read(loansRepositoryProvider).reject(loan.id);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        if (screenContext.mounted) {
          AppSnackbar.showInfo(screenContext, title: 'Loan rejected', message: loan.purpose);
        }
      } catch (_) {
        if (screenContext.mounted) {
          AppSnackbar.showError(
            screenContext,
            title: 'Could not reject loan',
            message: 'Something went wrong. Please try again.',
          );
        }
      }
    }

    Future<void> approve(BuildContext sheetContext) async {
      try {
        final rate = double.tryParse(rateController.text) ?? 0;
        final months = int.tryParse(monthsController.text) ?? 6;
        final totalPayable = loan.amount * (1 + (rate / 100) * (months / 12));
        await ref.read(loansRepositoryProvider).approve(
              loanId: loan.id,
              interestRatePercent: rate,
              repaymentMonths: months,
              totalPayable: totalPayable,
            );
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        if (screenContext.mounted) {
          AppSnackbar.showSuccess(
            screenContext,
            title: 'Loan approved',
            message: 'Repayment schedule set for ${loan.borrowerName ?? 'the borrower'}.',
          );
        }
      } catch (_) {
        if (screenContext.mounted) {
          AppSnackbar.showError(
            screenContext,
            title: 'Could not approve loan',
            message: 'Something went wrong. Please try again.',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Review loan request', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Interest rate (% p.a.)',
              controller: rateController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Repayment period (months)',
              controller: monthsController,
              keyboardType: TextInputType.number,
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
    );
  }
}
