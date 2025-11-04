import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
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
        // Try to add directly to Firebase
        await _remoteRepository.addTransaction(newTransaction);
      } catch (e) {
        // If Firebase fails, save locally for later sync
        await _offlineRepository.savePendingTransaction(newTransaction);
        rethrow;
      }
    } else {
      // Save locally when offline
      await _offlineRepository.savePendingTransaction(newTransaction);
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
        'Rent',
        'Utilities',
        'Salaries',
        'Supplies',
        'Marketing',
        'Transportation',
        'Other Expense',
      ];
    }
  }

  @override
  Future<Map<String, String>> uploadAttachment(File file, String type) async {
    // Attachments require online connection
    final isOnline = await _connectivityService.checkConnection();

    if (!isOnline) {
      throw Exception('File upload requires internet connection');
    }

    return await _remoteRepository.uploadAttachment(file, type);
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
