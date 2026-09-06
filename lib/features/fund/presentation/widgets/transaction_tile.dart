import 'package:flutter/material.dart';

import '../../../../core/theme/finance_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/fund_transaction.dart';

/// A single ledger row — reused by the dashboard's recent-transactions
/// preview and the full transaction/ledger screens.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final FundTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final color = transaction.type.isInflow ? finance.income : finance.expense;
    final sign = transaction.type.isInflow ? '+' : '−';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(transaction.type.icon, color: color, size: 20),
      ),
      title: Text(transaction.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        transaction.memberName != null
            ? '${transaction.memberName} • ${DateFormatter.shortDate(transaction.date)}'
            : DateFormatter.shortDate(transaction.date),
      ),
      trailing: Text(
        '$sign${CurrencyFormatter.format(transaction.amount)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
      ),
    );
  }
}
