import 'package:flutter/material.dart';

import '../../../../core/theme/finance_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/fund_transaction.dart';

/// A single ledger row — reused by the dashboard's recent-transactions
/// preview and the full transaction/ledger screens. [onCorrect], when
/// provided (admin-only, SRS §44), shows a small trailing action to open
/// the correction flow for this entry.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onCorrect});

  final FundTransaction transaction;
  final VoidCallback? onCorrect;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final color = transaction.isInflow ? finance.income : finance.expense;
    final sign = transaction.isInflow ? '+' : '−';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(transaction.type.icon, color: color, size: 20),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          transaction.memberName ?? transaction.recipient,
          DateFormatter.shortDate(transaction.date),
        ].whereType<String>().join(' • '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sign${CurrencyFormatter.format(transaction.amount)}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
          if (onCorrect != null)
            IconButton(
              tooltip: 'Correct this entry',
              icon: const Icon(Icons.edit_note_outlined, size: 20),
              onPressed: onCorrect,
            ),
        ],
      ),
    );
  }
}
