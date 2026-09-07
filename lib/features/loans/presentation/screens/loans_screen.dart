import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/loans_providers.dart';
import '../widgets/loan_card.dart';

/// SRS §15-§25 — "My loans" list with a request-loan entry point.
class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(myLoansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'loans_fab',
        onPressed: () => context.push(RoutePaths.loanRequest),
        icon: const Icon(Icons.add),
        label: const Text('Request loan'),
      ),
      body: loans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'No loans yet',
              message: 'Request a loan from the community fund any time.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => LoanCard(
              loan: items[index],
              onTap: () => context.push(RoutePaths.loanDetail(items[index].id)),
            ),
          );
        },
      ),
    );
  }
}
