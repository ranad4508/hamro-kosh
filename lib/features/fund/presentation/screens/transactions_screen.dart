import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/transaction_type.dart';
import '../../../../core/widgets/date_filter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/fund_providers.dart';
import '../widgets/transaction_tile.dart';

/// SRS §11-13, §42, §55 — full ledger with type + date-range filters, the
/// "never simply disappears" transparency view.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionType? _filter;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(
      ledgerTransactionsProvider((type: _filter, dateRange: _dateRange)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Ledger')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: DateFilter(
                    value: _dateRange,
                    onChanged: (range) => setState(() => _dateRange = range),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final type in TransactionType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(_typeLabel(type)),
                      selected: _filter == type,
                      onSelected: (_) => setState(() => _filter = type),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(message: '$error'),
              data: (items) {
                if (items.isEmpty) {
                  final filtering = _filter != null || _dateRange != null;
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: filtering
                        ? 'No matching transactions'
                        : 'No transactions yet',
                    message: filtering
                        ? 'Try a different type or date range.'
                        : 'Every fund movement will be recorded here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      TransactionTile(transaction: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.monthlyContribution => 'Monthly contribution',
    TransactionType.specialContribution => 'Special contribution',
    TransactionType.loanDisbursement => 'Loan disbursement',
    TransactionType.loanRepayment => 'Loan repayment',
    TransactionType.interestPayment => 'Interest',
    TransactionType.fundExpense => 'Fund expense',
    TransactionType.refund => 'Refund',
    TransactionType.adjustment => 'Adjustment',
    TransactionType.otherIncome => 'Other income',
    TransactionType.otherExpenditure => 'Other expenditure',
  };
}
