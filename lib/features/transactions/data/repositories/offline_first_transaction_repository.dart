import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phcl_accounts/core/services/connectivity_service.dart';
import 'package:phcl_accounts/features/transactions/data/repositories/offline_transaction_repository.dart';
import 'package:phcl_accounts/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/domain/repositories/transaction_repository.dart';

/// Enhanced transaction repository with offline-first capabilities.
///
/// This wrapper adds offline support to the existing FirebaseTransactionRepository:
/// - **Offline Detection**: Automatically detects connectivity status
/// - **Local Storage**: Saves transactions locally when offline
/// - **Automatic Sync**: Syncs data when connection is restored
/// - **Optimistic Updates**: Shows transactions immediately in UI
///
/// **Usage:**
/// Replace TransactionRepositoryImpl with OfflineFirstTransactionRepository
/// in your dependency injection setup.
class OfflineFirstTransactionRepository implements TransactionRepository {
  final TransactionRepositoryImpl _remoteRepository;
  final OfflineTransactionRepository _offlineRepository;
  final ConnectivityService _connectivityService;
  final FirebaseAuth _auth;

  OfflineFirstTransactionRepository({
    required TransactionRepositoryImpl remoteRepository,
    required OfflineTransactionRepository offlineRepository,
    required ConnectivityService connectivityService,
    required FirebaseAuth auth,
  }) : _remoteRepository = remoteRepository,
       _offlineRepository = offlineRepository,
       _connectivityService = connectivityService,
       _auth = auth;

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Create transaction with user info
    final newTransaction = TransactionEntity(
      type: transaction.type,
      category: transaction.category,
      date: transaction.date,
      amount: transaction.amount,
      clientId: transaction.clientId,
      contactNo: transaction.contactNo,
      note: transaction.note,
      attachmentUrl: transaction.attachmentUrl,
      attachmentType: transaction.attachmentType,
      createdBy: userId,
      createdAt: DateTime.now(),
      isDeleted: false,
      updatedBy: '',
      deletedBy: '',
      updatedAt: DateTime.now(),
      transactBy: transaction.transactBy,
    );

    // Check connectivity
    final isOnline = await _connectivityService.checkConnection();

    if (isOnline) {
      try {
        debugPrint(
          'OfflineFirstRepo: Online - Attempting to save to Firebase...',
        );
        // Try to add directly to Firebase
        await _remoteRepository.addTransaction(newTransaction);
        debugPrint('OfflineFirstRepo: Successfully saved to Firebase');
      } catch (e) {
        debugPrint(
          'OfflineFirstRepo: Firebase save failed - Saving locally. Error: $e',
        );
        // If Firebase fails, save locally for later sync
        // Extract local path if attachment URL is a local file path
        String? localPath;
        if (newTransaction.attachmentUrl != null &&
            newTransaction.attachmentUrl!.startsWith('/')) {
          localPath = newTransaction.attachmentUrl;
        }
        await _offlineRepository.savePendingTransaction(
          newTransaction,
          attachmentLocalPath: localPath,
        );
        rethrow;
      }
    } else {
      debugPrint('OfflineFirstRepo: Offline - Saving to local database');
      // Extract local path if attachment URL is a local file path
      String? localPath;
      if (newTransaction.attachmentUrl != null &&
          newTransaction.attachmentUrl!.startsWith('/')) {
        localPath = newTransaction.attachmentUrl;
      }

      // Save locally when offline
      await _offlineRepository.savePendingTransaction(
        newTransaction,
        attachmentLocalPath: localPath,
      );
      debugPrint('OfflineFirstRepo: Successfully saved to local DB');
      // Don't throw error - transaction saved locally
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    // Check connectivity
    final isOnline = await _connectivityService.checkConnection();

    if (isOnline) {
      try {
        // Fetch from Firebase when online
        return await _remoteRepository.getTransactions(
          startDate: startDate,
          endDate: endDate,
          type: type,
        );
      } catch (e) {
        // Fall back to local data if Firebase fails
        return await _getPendingTransactionsAsEntities();
      }
    } else {
      // Return local pending transactions when offline
      return await _getPendingTransactionsAsEntities();
    }
  }

  /// Converts pending transactions from local DB to entities.
  Future<List<TransactionEntity>> _getPendingTransactionsAsEntities() async {
    final pendingMaps = await _offlineRepository.getPendingTransactions();

    return pendingMaps.map((map) {
      return TransactionEntity(
        type: map['type'] as String,
        category: map['category'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        amount: map['amount'] as double,
        clientId: map['client_id'] as String?,
        contactNo: map['contact_no'] as String?,
        note: map['note'] as String?,
        attachmentUrl: map['attachment_url'] as String?,
        attachmentType: map['attachment_type'] as String?,
        transactBy: map['transact_by'] as String?,
        createdBy: map['created_by'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
        isDeleted: false,
        updatedBy: '',
        deletedBy: '',
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    // For now, updates require online connection
    final isOnline = await _connectivityService.checkConnection();

    if (!isOnline) {
      throw Exception('Update requires internet connection');
    }

    return await _remoteRepository.updateTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // For now, deletes require online connection
    final isOnline = await _connectivityService.checkConnection();

    if (!isOnline) {
      throw Exception('Delete requires internet connection');
    }

    return await _remoteRepository.deleteTransaction(id);
  }

  @override
  Future<List<String>> getCategories({required String type}) async {
    final isOnline = await _connectivityService.checkConnection();
    if (isOnline) {
      // Categories can be cached or use default list when offline
      try {
        final categories = await _remoteRepository.getCategories(type: type);
        return categories;
      } catch (e) {
        // Return default categories if offline
        return _getDefaultCategories(type);
      }
    } else {
      return _getDefaultCategories(type);
    }
  }

  /// Returns default categories when offline.
  List<String> _getDefaultCategories(String type) {
    if (type == 'income') {
      return ['Plot/Land Sale'];
    } else {
      return [
        'Advertisement & Publicity (Facebook Boosting & Other\'s)',
        'Cleaner Bill Monthly',
        'Company Brochure Making Exp.',
        'Conveyance Bill\'s',
        'Entertainment (Client & Management Gust)',
        'Festival (Eid) Tips exp',
        'Internet Bill',
        'Lunch Bill',
        'Monthly Mobile Bill',
        'Monthly Rent Car Bill',
        'Monthly Staff Salary',
        'Newspaper Bill',
        'Office Electricity Bill Monthly',
        'Office Other\'s/Miscellaneous Exp',
        'Office Rent Monthly',
        'Office Service Charge Monthly',
        'Office Stationery Expence.',
        'Project Purpose Payment To (Mr.Sharif)',
        'Project visit Rent Car Bill',
        'Promotional Leaflet Exp.',
        'Remuneration',
        'Repair & Maintenance expence',
        'SMS Marketing Purpose Exp',
        'Sales Incentive\'s',
        'Staff ID Card Visiting Card Expence',
        'Wages Pay Exp.',
        'Water Bill\'s Exp.',
      ];
    }
  }

  @override
  Future<Map<String, String>> uploadAttachment(File file, String type) async {
    // Check connectivity
    final isOnline = await _connectivityService.checkConnection();

    if (isOnline) {
      // Upload directly to Firebase when online
      try {
        debugPrint(
          'OfflineFirstRepo: Online - Uploading attachment to Firebase...',
        );
        final result = await _remoteRepository.uploadAttachment(file, type);
        debugPrint('OfflineFirstRepo: Attachment uploaded successfully');
        return result;
      } catch (e) {
        debugPrint('OfflineFirstRepo: Firebase upload failed - $e');
        // If upload fails, save locally for later sync
        return await _saveAttachmentLocally(file, type);
      }
    } else {
      // Save locally when offline
      debugPrint('OfflineFirstRepo: Offline - Saving attachment locally...');
      return await _saveAttachmentLocally(file, type);
    }
  }

  /// Saves attachment file to local storage for later upload.
  ///
  /// Creates a local copy of the file in the app's documents directory.
  /// Returns a map with:
  /// - 'url': Local file path (to be replaced with Firebase URL after sync)
  /// - 'type': File type (image, pdf, etc.)
  ///
  /// The file will be uploaded to Firebase during sync.
  Future<Map<String, String>> _saveAttachmentLocally(
    File file,
    String type,
  ) async {
    try {
      // Get app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/offline_attachments');

      // Create directory if it doesn't exist
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = 'attachment_$timestamp.$extension';
      final localPath = '${attachmentsDir.path}/$fileName';

      // Copy file to local storage
      final localFile = await file.copy(localPath);

      debugPrint('OfflineFirstRepo: Attachment saved locally at: $localPath');

      return {
        'url': localFile.path, // Local path, will be replaced after sync
        'type': type,
      };
    } catch (e) {
      debugPrint('OfflineFirstRepo: Error saving attachment locally - $e');
      throw Exception('Failed to save attachment locally: $e');
    }
  }

  @override
  Future<void> deleteAttachment(String url) async {
    // Attachment deletion requires online connection
    final isOnline = await _connectivityService.checkConnection();

    if (!isOnline) {
      throw Exception('File deletion requires internet connection');
    }

    return await _remoteRepository.deleteAttachment(url);
  }
}
