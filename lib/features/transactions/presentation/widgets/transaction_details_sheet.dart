import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/core/services/pdf_receipt_service.dart';
import 'package:phcl_accounts/core/widgets/attachment_viewer.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.category,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildActionButtons(context),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          transaction.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(symbol: '৳ ').format(transaction.amount),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Transaction Details
                  _buildDetailRow('Date', DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.date)),
                  if (transaction.clientId != null && transaction.clientId != '')
                    _buildDetailRow('Client ID', transaction.clientId!),
                  if (transaction.contactNo != null && transaction.contactNo != '')
                    _buildDetailRow('Contact No', transaction.contactNo!),
                  if (transaction.note != null && transaction.note != '')
                    _buildDetailRow('Note', transaction.note!),
                  if (transaction.id != null)
                    _buildDetailRow('Transaction ID', transaction.id!),
                  
                  if (transaction.attachmentUrl != null && transaction.attachmentUrl != '') ...[
                    const SizedBox(height: 16),
                    _buildAttachmentSection(),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _shareReceipt(context),
          icon: const Icon(Icons.share),
          tooltip: 'Share Receipt',
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _downloadReceipt(context),
          icon: const Icon(Icons.download),
          tooltip: 'Download Receipt',
          style: IconButton.styleFrom(
            backgroundColor: Colors.green[50],
            foregroundColor: Colors.green[700],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            'Attachment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Text(':'),
        const SizedBox(width: 8),
        AttachmentViewer(
          url: transaction.attachmentUrl!, 
          fileName: '${transaction.category}_${transaction.id}_attachment',
          fileType: transaction.attachmentType,
        ),
      ],
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Generating receipt...');
      await PdfReceiptService.generateAndShareReceipt(transaction);
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Preparing download...');
      await PdfReceiptService.downloadReceipt(transaction);
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(':'),
          const SizedBox(width: 8),
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