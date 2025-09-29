import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';

class TransactionItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == 'income';
    final color = isIncome ? theme.colorScheme.tertiary : theme.colorScheme.error;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.all(0),
      child: ListTile(
        tileColor: theme.colorScheme.surfaceContainer,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction.category),
        subtitle: Text(
          DateFormat('MMM dd, yyyy').format(transaction.date),
        ),
        trailing: Text(
          NumberFormat.currency(symbol: '৳ ').format(transaction.amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}