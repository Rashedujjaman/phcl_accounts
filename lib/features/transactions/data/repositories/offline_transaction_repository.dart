import 'package:uuid/uuid.dart';
import 'package:phcl_accounts/core/database/local_database.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';

/// Repository for managing offline transaction storage.
///
/// Provides local database operations for:
/// - **Saving** transactions created while offline
/// - **Querying** pending transactions for display
/// - **Managing** sync queue and retry logic
///
/// Works in conjunction with SyncService to upload data when online.
class OfflineTransactionRepository {
  final _uuid = const Uuid();

  /// Saves a transaction to local database for later sync.
  ///
  /// **Process:**
  /// 1. Generates a unique local ID
  /// 2. Stores transaction with 'pending' sync status
  /// 3. Returns the local ID for immediate UI updates
  ///
  /// The transaction will be automatically synced to Firebase
  /// when network connection is restored.
  ///
  /// Parameters:
  /// - [transaction]: The transaction entity to save locally
  /// - [attachmentLocalPath]: Optional local path to attachment file
  ///
  /// Returns:
  /// - String: Unique local ID for tracking the transaction
  Future<String> savePendingTransaction(
    TransactionEntity transaction, {
    String? attachmentLocalPath,
  }) async {
    final db = await LocalDatabase.database;
    final localId = _uuid.v4();

    await db.insert(LocalDatabase.pendingTransactionsTable, {
      'local_id': localId,
      'type': transaction.type,
      'category': transaction.category,
      'date': transaction.date.millisecondsSinceEpoch,
      'amount': transaction.amount,
      'client_id': transaction.clientId,
      'contact_no': transaction.contactNo,
      'note': transaction.note,
      'attachment_url': transaction.attachmentUrl,
      'attachment_type': transaction.attachmentType,
      'attachment_local_path': attachmentLocalPath, // Store local path
      'transact_by': transaction.transactBy,
      'created_by': transaction.createdBy,
      'created_at':
          (transaction.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      'sync_status': 'pending',
      'retry_count': 0,
    });

    return localId;
  }

  /// Retrieves all pending transactions awaiting sync.
  ///
  /// Returns transactions that are:
  /// - Currently pending sync ('pending' status)
  /// - Failed with retries remaining
  ///
  /// Useful for displaying offline transactions in the UI before sync.
  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await LocalDatabase.database;

    return await db.query(
      LocalDatabase.pendingTransactionsTable,
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending', 'syncing'],
      orderBy: 'created_at DESC',
    );
  }

  /// Gets the count of transactions waiting to be synced.
  ///
  /// Useful for showing sync badges or status indicators in the UI.
  Future<int> getPendingCount() async {
    final db = await LocalDatabase.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM ${LocalDatabase.pendingTransactionsTable}
      WHERE sync_status = 'pending'
    ''');

    return result.first['count'] as int;
  }

  /// Gets transactions that failed to sync.
  ///
  /// Returns transactions that exceeded maximum retry attempts.
  /// These may require manual intervention or user notification.
  Future<List<Map<String, dynamic>>> getFailedTransactions() async {
    final db = await LocalDatabase.database;

    return await db.query(
      LocalDatabase.pendingTransactionsTable,
      where: 'sync_status = ?',
      whereArgs: ['failed'],
      orderBy: 'created_at DESC',
    );
  }

  /// Resets a failed transaction to allow retry.
  ///
  /// Useful for manual retry after fixing issues or when user requests.
  ///
  /// Parameters:
  /// - [localId]: The local ID of the transaction to retry
  Future<void> retryFailedTransaction(String localId) async {
    final db = await LocalDatabase.database;

    await db.update(
      LocalDatabase.pendingTransactionsTable,
      {'sync_status': 'pending', 'retry_count': 0, 'error_message': null},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Deletes a pending transaction from local storage.
  ///
  /// Use with caution - only for user-initiated deletion of unsynced data.
  ///
  /// Parameters:
  /// - [localId]: The local ID of the transaction to delete
  Future<void> deletePendingTransaction(String localId) async {
    final db = await LocalDatabase.database;

    await db.delete(
      LocalDatabase.pendingTransactionsTable,
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Clears all successfully synced transactions from local storage.
  ///
  /// Called periodically or after successful sync to free up space.
  Future<void> clearSyncedTransactions() async {
    final db = await LocalDatabase.database;

    await db.delete(
      LocalDatabase.pendingTransactionsTable,
      where: 'sync_status = ? AND firebase_id IS NOT NULL',
      whereArgs: ['synced'],
    );
  }
}
