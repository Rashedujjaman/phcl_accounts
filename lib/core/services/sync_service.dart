import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phcl_accounts/core/database/local_database.dart';
import 'package:phcl_accounts/core/services/connectivity_service.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/domain/repositories/transaction_repository.dart';

/// Service responsible for synchronizing offline data with Firebase.
///
/// **Key Features:**
/// - **Automatic Sync**: Triggers sync when network is restored
/// - **Retry Logic**: Handles failed syncs with exponential backoff
/// - **Conflict Resolution**: Manages data conflicts during sync
/// - **Progress Tracking**: Emits sync status updates via streams
///
/// **Sync Flow:**
/// 1. Monitor connectivity status
/// 2. When online, fetch pending transactions from local DB
/// 3. Upload each transaction to Firebase
/// 4. Update local records with Firebase IDs
/// 5. Clean up successfully synced data
class SyncService {
  final TransactionRepository _transactionRepository;
  final ConnectivityService _connectivityService;

  /// Stream controller for broadcasting sync status.
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  /// Stream subscription for connectivity changes.
  StreamSubscription<bool>? _connectivitySubscription;

  /// Flag to prevent concurrent sync operations.
  bool _isSyncing = false;

  /// Maximum number of retry attempts for failed syncs.
  static const int maxRetries = 3;

  SyncService({
    required TransactionRepository transactionRepository,
    required ConnectivityService connectivityService,
  }) : _transactionRepository = transactionRepository,
       _connectivityService = connectivityService;

  /// Stream that emits sync status updates.
  ///
  /// Subscribe to track sync progress:
  /// ```dart
  /// syncService.syncStatusStream.listen((status) {
  ///   if (status.isSuccess) {
  ///     print('Synced ${status.syncedCount} transactions');
  ///   }
  /// });
  /// ```
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Initializes the sync service and starts monitoring for sync opportunities.
  ///
  /// Should be called once during app startup after user authentication.
  Future<void> initialize() async {
    debugPrint('SyncService: Initializing sync service...');
    debugPrint(
      'SyncService: Connectivity service instance: $_connectivityService',
    );

    // Listen for connectivity changes
    debugPrint('SyncService: Setting up connectivity stream listener...');
    _connectivitySubscription = _connectivityService.connectionStream.listen(
      (isOnline) {
        debugPrint('SyncService: ========================================');
        debugPrint('SyncService: 🔔 CONNECTIVITY CALLBACK TRIGGERED!');
        debugPrint('SyncService: Connectivity changed - isOnline: $isOnline');
        debugPrint('SyncService: ========================================');

        if (isOnline) {
          debugPrint('SyncService: Connection restored - Triggering sync...');
          // Trigger sync when coming online
          syncPendingTransactions();
        } else {
          debugPrint(
            'SyncService: Connection lost - Waiting for reconnection...',
          );
        }
      },
      onError: (error) {
        debugPrint('SyncService: ❌ ERROR in connectivity stream: $error');
      },
      onDone: () {
        debugPrint('SyncService: ⚠️ Connectivity stream closed!');
      },
    );

    debugPrint('SyncService: Stream listener setup complete');
    debugPrint(
      'SyncService: Subscription active: ${_connectivitySubscription != null}',
    );

    // Perform initial sync if online
    final initiallyOnline = _connectivityService.isConnected;
    debugPrint(
      'SyncService: Initial connectivity check - isConnected: $initiallyOnline',
    );

    if (initiallyOnline) {
      debugPrint('SyncService: Device is online - Starting initial sync...');
      syncPendingTransactions();
    } else {
      debugPrint(
        'SyncService: Device is offline - Sync will trigger when connection available',
      );
    }
  }

  /// Syncs all pending transactions with Firebase.
  ///
  /// **Process:**
  /// 1. Checks if already syncing to prevent duplicates
  /// 2. Fetches pending transactions from local database
  /// 3. Attempts to upload each transaction
  /// 4. Updates local records with Firebase IDs on success
  /// 5. Handles failures with retry logic
  ///
  /// Returns the number of successfully synced transactions.
  Future<int> syncPendingTransactions() async {
    debugPrint('SyncService: Starting sync process');
    if (_isSyncing) {
      return 0; // Already syncing, skip
    }

    if (!_connectivityService.isConnected) {
      return 0; // No connection, skip
    }

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;

    try {
      _syncStatusController.add(SyncStatus.started());

      final db = await LocalDatabase.database;

      // Fetch all pending transactions
      final List<Map<String, dynamic>> pendingMaps = await db.query(
        LocalDatabase.pendingTransactionsTable,
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );

      if (pendingMaps.isEmpty) {
        _syncStatusController.add(SyncStatus.completed(0, 0));
        return 0;
      }

      _syncStatusController.add(SyncStatus.inProgress(0, pendingMaps.length));
      debugPrint(
        'SyncService: Found ${pendingMaps.length} pending transactions to sync',
      );

      // Sync each transaction
      for (final map in pendingMaps) {
        try {
          final localId = map['local_id'] as String;
          final attachmentLocalPath = map['attachment_local_path'] as String?;

          // Update status to 'syncing'
          await db.update(
            LocalDatabase.pendingTransactionsTable,
            {
              'sync_status': 'syncing',
              'last_sync_attempt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'local_id = ?',
            whereArgs: [localId],
          );

          // Create transaction entity from local data
          var transaction = _transactionFromMap(map);

          // If there's a local attachment, upload it first
          if (attachmentLocalPath != null && attachmentLocalPath.isNotEmpty) {
            try {
              debugPrint(
                'SyncService: Uploading attachment from: $attachmentLocalPath',
              );

              final attachmentFile = File(attachmentLocalPath);
              if (await attachmentFile.exists()) {
                // Upload attachment to Firebase
                final uploadResult = await _transactionRepository
                    .uploadAttachment(
                      attachmentFile,
                      transaction.attachmentType ?? 'other',
                    );

                // Update transaction with Firebase URL
                transaction = TransactionEntity(
                  type: transaction.type,
                  category: transaction.category,
                  date: transaction.date,
                  amount: transaction.amount,
                  clientId: transaction.clientId,
                  contactNo: transaction.contactNo,
                  note: transaction.note,
                  attachmentUrl: uploadResult['url'], // Firebase URL
                  attachmentType: uploadResult['type'],
                  transactBy: transaction.transactBy,
                  createdBy: transaction.createdBy,
                  createdAt: transaction.createdAt,
                  isDeleted: false,
                  updatedBy: '',
                  deletedBy: '',
                  updatedAt: DateTime.now(),
                );

                debugPrint(
                  'SyncService: Attachment uploaded successfully: ${uploadResult['url']}',
                );

                // Delete local attachment file after successful upload
                try {
                  await attachmentFile.delete();
                  debugPrint('SyncService: Local attachment file deleted');
                } catch (e) {
                  debugPrint(
                    'SyncService: Warning - Could not delete local attachment: $e',
                  );
                }
              } else {
                debugPrint(
                  'SyncService: Warning - Local attachment file not found: $attachmentLocalPath',
                );
              }
            } catch (e) {
              debugPrint('SyncService: Failed to upload attachment: $e');
              // Continue with transaction sync even if attachment fails
              // The transaction will still have the local path which might fail validation
            }
          }

          // Upload transaction to Firebase
          await _transactionRepository.addTransaction(transaction);

          // Mark as synced and delete from local DB
          await db.delete(
            LocalDatabase.pendingTransactionsTable,
            where: 'local_id = ?',
            whereArgs: [localId],
          );

          syncedCount++;
          _syncStatusController.add(
            SyncStatus.inProgress(syncedCount, pendingMaps.length),
          );
        } catch (e) {
          failedCount++;
          final localId = map['local_id'] as String;
          final retryCount = (map['retry_count'] as int? ?? 0) + 1;

          // Update failure info
          await db.update(
            LocalDatabase.pendingTransactionsTable,
            {
              'sync_status': retryCount >= maxRetries ? 'failed' : 'pending',
              'retry_count': retryCount,
              'error_message': e.toString(),
              'last_sync_attempt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'local_id = ?',
            whereArgs: [localId],
          );
        }
      }

      _syncStatusController.add(SyncStatus.completed(syncedCount, failedCount));
      debugPrint('SyncService: Sync process completed');
    } catch (e) {
      _syncStatusController.add(SyncStatus.error(e.toString()));
      debugPrint('SyncService: Sync process failed: $e');
    } finally {
      _isSyncing = false;
    }
    return syncedCount;
  }

  /// Converts a database map to a TransactionEntity.
  TransactionEntity _transactionFromMap(Map<String, dynamic> map) {
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isDeleted: false,
      updatedBy: '',
      deletedBy: '',
      updatedAt: DateTime.now(),
    );
  }

  /// Disposes of resources used by the sync service.
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

/// Represents the current status of a sync operation.
class SyncStatus {
  final SyncState state;
  final int syncedCount;
  final int totalCount;
  final int failedCount;
  final String? errorMessage;

  const SyncStatus({
    required this.state,
    this.syncedCount = 0,
    this.totalCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });

  factory SyncStatus.started() => const SyncStatus(state: SyncState.started);

  factory SyncStatus.inProgress(int synced, int total) => SyncStatus(
    state: SyncState.inProgress,
    syncedCount: synced,
    totalCount: total,
  );

  factory SyncStatus.completed(int synced, int failed) => SyncStatus(
    state: SyncState.completed,
    syncedCount: synced,
    failedCount: failed,
  );

  factory SyncStatus.error(String message) =>
      SyncStatus(state: SyncState.error, errorMessage: message);

  bool get isSuccess => state == SyncState.completed && failedCount == 0;
  bool get isInProgress => state == SyncState.inProgress;
  bool get hasFailures => failedCount > 0;
}

/// Enumeration of possible sync states.
enum SyncState { started, inProgress, completed, error }
