import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';

/// Service class for generating PDF receipts from transactions
/// 
/// This service provides functionality to:
/// - Generate professional PDF receipts
/// - Embed image attachments
/// - Create QR codes for non-image attachments
/// - Share receipts with original attachment files
class PdfReceiptService {
  /// Generates a PDF receipt and shares it along with any attachments
  static Future<void> generateAndShareReceipt(TransactionEntity transaction) async {
    try {
      final pdf = await _generatePdf(transaction);
      final output = await getTemporaryDirectory();
      final receiptFile = File('${output.path}/receipt_${transaction.id}.pdf');
      await receiptFile.writeAsBytes(await pdf.save());
      
      // Create list of files to share
      List<XFile> filesToShare = [XFile(receiptFile.path)];
      
      // Include attachment file if available
      if (transaction.attachmentUrl != null) {
        try {
          final attachmentFile = await _downloadAttachmentFile(transaction);
          if (attachmentFile != null) {
            filesToShare.add(XFile(attachmentFile.path));
          }
        } catch (e) {
          rethrow;
        }
      }
      
      await Share.shareXFiles(
        filesToShare,
        text: filesToShare.length > 1 
            ? 'Transaction Receipt with Attachment - ${transaction.category}'
            : 'Transaction Receipt - ${transaction.category}',
        subject: 'Transaction Receipt',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Downloads and opens PDF receipt in system PDF viewer
  static Future<void> downloadReceipt(TransactionEntity transaction) async {
    try {
      final pdf = await _generatePdf(transaction);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'receipt_${transaction.category}_${(transaction.amount)}.pdf',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Generates the PDF document with transaction details and attachments
  static Future<pw.Document> _generatePdf(TransactionEntity transaction) async {
    final pdf = pw.Document();
    final isIncome = transaction.type == 'income';
    
    // Prepare image attachment if exists
    pw.ImageProvider? attachmentImage;
    if (transaction.attachmentUrl != null && _isImageFile(transaction.attachmentType)) {
      try {
        attachmentImage = await _downloadAndPrepareImage(transaction.attachmentUrl!);
      } catch (e) {
        rethrow;
      }
    }
    
    // Add receipt page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => _buildReceiptContent(transaction, isIncome, attachmentImage),
      ),
    );
    return pdf;
  }

  /// Builds the main content of the receipt
  static pw.Widget _buildReceiptContent(
    TransactionEntity transaction,
    bool isIncome,
    pw.ImageProvider? attachmentImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        pw.SizedBox(height: 30),
        
        // Receipt Details Box
        _buildReceiptDetailsBox(transaction, isIncome, attachmentImage),
        pw.Spacer(),
        
        // Footer
        _buildFooter(transaction),
      ],
    );
  }

  /// Builds the header section
  static pw.Widget _buildHeader() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'PHCL ACCOUNTS',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Transaction Receipt',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main receipt details container
  static pw.Widget _buildReceiptDetailsBox(
    TransactionEntity transaction,
    bool isIncome,
    pw.ImageProvider? attachmentImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Transaction Type and Amount
          _buildTransactionHeader(transaction, isIncome),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 20),
          
          // Transaction Details
          ..._buildTransactionDetails(transaction),
          
          // Attachment section
          if (transaction.attachmentUrl != null) ...[
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            _buildAttachmentSection(transaction, attachmentImage),
          ],
          
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          
          // Summary
          _buildSummary(transaction, isIncome),
        ],
      ),
    );
  }

  /// Builds the transaction type and amount header
  static pw.Widget _buildTransactionHeader(TransactionEntity transaction, bool isIncome) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Transaction Type',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              transaction.type.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: isIncome ? PdfColors.green800 : PdfColors.red800,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Amount',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              '${NumberFormat('#,###.00').format(transaction.amount)} BDT',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: isIncome ? PdfColors.green800 : PdfColors.red800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the list of transaction detail rows
  static List<pw.Widget> _buildTransactionDetails(TransactionEntity transaction) {
    final details = <pw.Widget>[
      _buildDetailRow('Category', transaction.category),
      _buildDetailRow('Date', DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.date)),
    ];
    
    if (transaction.clientId != null) {
      details.add(_buildDetailRow('Client ID', transaction.clientId!));
    }
    if (transaction.contactNo != null) {
      details.add(_buildDetailRow('Contact No', transaction.contactNo!));
    }
    if (transaction.note != null) {
      details.add(_buildDetailRow('Note', transaction.note!));
    }
    if (transaction.id != null) {
      details.add(_buildDetailRow('Transaction ID', transaction.id!));
    }
    
    return details;
  }

  /// Builds the summary section
  static pw.Widget _buildSummary(TransactionEntity transaction, bool isIncome) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: isIncome ? PdfColors.green50 : PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Total ${transaction.type.toUpperCase()}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '${NumberFormat('#,###.00').format(transaction.amount)} BDT',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: isIncome ? PdfColors.green800 : PdfColors.red800,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the footer section
  static pw.Widget _buildFooter(TransactionEntity transaction) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'Generated on ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This is a computer-generated receipt.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          if (transaction.attachmentUrl != null && !_isImageFile(transaction.attachmentType))
            pw.Text(
              'Scan QR code above to access attachment file.',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey500,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a detail row with label and value
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Text(' : ', style: pw.TextStyle(fontSize: 12)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the attachment section with image or QR code
  static pw.Widget _buildAttachmentSection(TransactionEntity transaction, pw.ImageProvider? attachmentImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Attachment',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        
        if (attachmentImage != null) ...[
          // Image attachment
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attached Image:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Container(
                    height: 225,
                    width: 300,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Image(
                      attachmentImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (transaction.attachmentUrl != null) ...[
          // Non-image attachment with QR code for access
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      _getFileIcon(transaction.attachmentType),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Attachment File',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Type: ${transaction.attachmentType?.toUpperCase() ?? 'Unknown'}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      if (!_isImageFile(transaction.attachmentType))
                        pw.Text(
                          'Scan QR code to access attachment file',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey500,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                // QR Code for all non-image files
                if (!_isImageFile(transaction.attachmentType))
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: _buildQrCode(transaction.attachmentUrl!),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds a QR code widget for attachment access
  static pw.Widget _buildQrCode(String url) {
    try {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: url,
          width: 60,
          height: 60,
        ),
      );
    } catch (e) {
      return pw.Container(
        width: 60,
        height: 60,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Center(
          child: pw.Text(
            'QR',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ),
      );
    }
  }

  /// Checks if the file type is an image
  static bool _isImageFile(String? fileType) {
    if (fileType == null) return false;
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileType.toLowerCase());
  }

  /// Returns the appropriate file icon text for the file type
  static String _getFileIcon(String? fileType) {
    if (fileType == null) return 'FILE';
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'doc':
      case 'docx':
        return 'DOC';
      case 'xls':
      case 'xlsx':
        return 'XLS';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'IMG';
      default:
        return 'FILE';
    }
  }

  /// Downloads and prepares an image for PDF embedding
  static Future<pw.ImageProvider?> _downloadAndPrepareImage(String imageUrl) async {
    try {
      final response = await _downloadFile(imageUrl);
      if (response != null) {
        return pw.MemoryImage(response);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Downloads attachment file for sharing
  static Future<File?> _downloadAttachmentFile(TransactionEntity transaction) async {
    try {
      if (transaction.attachmentUrl == null) return null;
      
      final response = await _downloadFile(transaction.attachmentUrl!);
      if (response != null) {
        final output = await getTemporaryDirectory();
        final fileExtension = transaction.attachmentType ?? 'file';
        final file = File('${output.path}/attachment_${transaction.id}.$fileExtension');
        await file.writeAsBytes(response);
        return file;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Downloads file from URL and returns as bytes
  static Future<Uint8List?> _downloadFile(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }
}
