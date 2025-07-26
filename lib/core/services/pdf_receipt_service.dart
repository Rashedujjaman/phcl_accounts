import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class PdfReceiptService {
  static Future<void> generateAndShareReceipt(TransactionEntity transaction) async {
    try {
      final pdf = await _generatePdf(transaction);
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_${transaction.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Transaction Receipt - ${transaction.category}',
        subject: 'Transaction Receipt',
      );
    } catch (e) {
      throw Exception('Failed to generate receipt: $e');
    }
  }

  static Future<void> downloadReceipt(TransactionEntity transaction) async {
    try {
      final pdf = await _generatePdf(transaction);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'receipt_${transaction.category}_${(transaction.amount)}.pdf',
      );
    } catch (e) {
      throw Exception('Failed to download receipt: $e');
    }
  }

  static Future<pw.Document> _generatePdf(TransactionEntity transaction) async {
    final pdf = pw.Document();
    final isIncome = transaction.type == 'income';
    
    // Download and prepare attachment if exists
    pw.ImageProvider? attachmentImage;
    if (transaction.attachmentUrl != null && _isImageFile(transaction.attachmentType)) {
      try {
        attachmentImage = await _downloadAndPrepareImage(transaction.attachmentUrl!);
      } catch (e) {
        print('Failed to load attachment image: $e');
      }
    }
    
    // Add main receipt page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
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
              ),
              
              pw.SizedBox(height: 30),
              
              // Receipt Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Transaction Type and Amount
                    pw.Row(
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
                    ),
                    
                    pw.SizedBox(height: 20),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 20),
                    
                    // Transaction Details
                    _buildDetailRow('Category', transaction.category),
                    _buildDetailRow('Date', DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.date)),
                    if (transaction.clientId != null)
                      _buildDetailRow('Client ID', transaction.clientId!),
                    if (transaction.contactNo != null)
                      _buildDetailRow('Contact No', transaction.contactNo!),
                    if (transaction.note != null)
                      _buildDetailRow('Note', transaction.note!),
                    if (transaction.id != null)
                      _buildDetailRow('Transaction ID', transaction.id!),
                    
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
                    pw.Container(
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
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
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
                        'Original attachment file is referenced above.',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Add a separate page for large images if the image exists
    // if (attachmentImage != null) {
    //   pdf.addPage(
    //     pw.Page(
    //       pageFormat: PdfPageFormat.a4,
    //       margin: const pw.EdgeInsets.all(32),
    //       build: (pw.Context context) {
    //         return pw.Column(
    //           crossAxisAlignment: pw.CrossAxisAlignment.start,
    //           children: [
    //             pw.Text(
    //               'Transaction Attachment',
    //               style: pw.TextStyle(
    //                 fontSize: 20,
    //                 fontWeight: pw.FontWeight.bold,
    //               ),
    //             ),
    //             pw.SizedBox(height: 8),
    //             pw.Text(
    //               'Category: ${transaction.category}',
    //               style: pw.TextStyle(
    //                 fontSize: 14,
    //                 color: PdfColors.grey600,
    //               ),
    //             ),
    //             pw.Text(
    //               'Date: ${DateFormat('MMM dd, yyyy').format(transaction.date)}',
    //               style: pw.TextStyle(
    //                 fontSize: 14,
    //                 color: PdfColors.grey600,
    //               ),
    //             ),
    //             pw.SizedBox(height: 20),
    //             pw.Expanded(
    //               child: pw.Center(
    //                 child: pw.Container(
    //                   decoration: pw.BoxDecoration(
    //                     border: pw.Border.all(color: PdfColors.grey300),
    //                   ),
    //                   child: pw.Image(
    //                     attachmentImage!,
    //                     fit: pw.BoxFit.contain,
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ],
    //         );
    //       },
    //     ),
    //   );
    // }
    
    return pdf;
  }

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
                    // constraints: const pw.BoxConstraints(
                      
                    //   // maxWidth: 300,
                    //   // maxHeight: 200,
                    // ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                      color: PdfColors.green,
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
          // Non-image attachment (show reference)
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
                        fontSize: 16,
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
                      pw.Text(
                        'Note: Original file attached to transaction',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static bool _isImageFile(String? fileType) {
    if (fileType == null) return false;
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileType.toLowerCase());
  }

  static String _getFileIcon(String? fileType) {
    if (fileType == null) return '📄';
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      default:
        return '📄';
    }
  }

  static Future<pw.ImageProvider?> _downloadAndPrepareImage(String imageUrl) async {
    try {
      // Import http package temporarily for this function
      final response = await _downloadFile(imageUrl);
      if (response != null) {
        return pw.MemoryImage(response);
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  static Future<Uint8List?> _downloadFile(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }
}
