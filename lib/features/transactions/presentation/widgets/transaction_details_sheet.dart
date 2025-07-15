import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/core/widgets/attachment_viewer.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/presentation/pages/add_transaction_page.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              transaction.category,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(),
          _buildDetailRow('Type', transaction.type.capitalize(), color: color),
          _buildDetailRow('Amount', 
              NumberFormat.currency(symbol: '৳ ').format(transaction.amount),
              color: color),
          _buildDetailRow('Date', 
              DateFormat('MMM dd, yyyy').format(transaction.date)),
          if (transaction.clientId != null)
            _buildDetailRow('Client ID', transaction.clientId!),
          if (transaction.contactNo != null)
            _buildDetailRow('Contact No', transaction.contactNo!),
          if (transaction.note != null)
            _buildDetailRow('Note', transaction.note!),
          if (transaction.attachmentUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Attachment',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: AttachmentViewer(
                    url: transaction.attachmentUrl!, 
                    fileName: '${transaction.category}_${transaction.id}_attachment',
                    fileType: transaction.attachmentType,
                  ),)

                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}