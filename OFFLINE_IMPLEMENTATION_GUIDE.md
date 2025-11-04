# 🚀 Offline-First Transaction Implementation Guide

## Overview

This guide explains how to integrate offline-first transaction capabilities into your PHCL Accounts app. Users can now create transactions while offline, and they will automatically sync when internet connection is restored.

## 📋 What Was Added

### 1. **New Dependencies**

- `sqflite: ^2.4.1` - Local SQLite database for offline storage
- `connectivity_plus: ^6.1.1` - Network connectivity monitoring

### 2. **New Core Services**

#### **LocalDatabase** (`lib/core/database/local_database.dart`)

- Manages SQLite database with two main tables:
  - `pending_transactions`: Stores offline transactions
  - `sync_queue`: Tracks pending sync operations
- Handles database initialization and schema migrations

#### **ConnectivityService** (`lib/core/services/connectivity_service.dart`)

- Monitors network connectivity status
- Provides real-time stream of connection changes
- Used to trigger automatic sync when online

#### **SyncService** (`lib/core/services/sync_service.dart`)

- Automatically syncs pending transactions when online
- Implements retry logic with exponential backoff
- Emits sync status updates via streams
- Maximum 3 retry attempts for failed syncs

### 3. **New Repository Layer**

#### **OfflineTransactionRepository** (`lib/features/transactions/data/repositories/offline_transaction_repository.dart`)

- Manages local database operations
- Saves pending transactions
- Queries unsynced data
- Tracks failed syncs for retry

#### **OfflineFirstTransactionRepository** (`lib/features/transactions/data/repositories/offline_first_transaction_repository.dart`)

- Wrapper around existing Firebase repository
- Automatically detects online/offline status
- Saves locally when offline, uploads to Firebase when online
- Falls back to local data if Firebase fails

## 🛠️ Integration Steps

### Step 1: Initialize Services (in your main.dart)

```dart
import 'package:phcl_accounts/core/services/connectivity_service.dart';
import 'package:phcl_accounts/core/services/sync_service.dart';
import 'package:phcl_accounts/features/transactions/data/repositories/offline_transaction_repository.dart';
import 'package:phcl_accounts/features/transactions/data/repositories/offline_first_transaction_repository.dart';

// In your main() function or dependency injection setup:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  runApp(MyApp(connectivityService: connectivityService));
}
```

### Step 2: Setup Dependency Injection

Update your app's dependency injection to use the new offline-first repository:

```dart
class MyApp extends StatelessWidget {
  final ConnectivityService connectivityService;

  const MyApp({Key? key, required this.connectivityService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Firebase services
        RepositoryProvider<FirebaseAuth>(
          create: (context) => FirebaseAuth.instance,
        ),
        RepositoryProvider<FirebaseFirestore>(
          create: (context) => FirebaseFirestore.instance,
        ),
        RepositoryProvider<FirebaseStorage>(
          create: (context) => FirebaseStorage.instance,
        ),

        // Connectivity service
        RepositoryProvider<ConnectivityService>.value(
          value: connectivityService,
        ),

        // Original Firebase repository
        RepositoryProvider<TransactionRepositoryImpl>(
          create: (context) => TransactionRepositoryImpl(
            firestore: context.read<FirebaseFirestore>(),
            storage: context.read<FirebaseStorage>(),
            auth: context.read<FirebaseAuth>(),
          ),
        ),

        // Offline transaction repository
        RepositoryProvider<OfflineTransactionRepository>(
          create: (context) => OfflineTransactionRepository(),
        ),

        // Offline-first wrapper (this is what your BLoC will use)
        RepositoryProvider<TransactionRepository>(
          create: (context) => OfflineFirstTransactionRepository(
            remoteRepository: context.read<TransactionRepositoryImpl>(),
            offlineRepository: context.read<OfflineTransactionRepository>(),
            connectivityService: context.read<ConnectivityService>(),
            auth: context.read<FirebaseAuth>(),
          ),
        ),

        // Sync service
        RepositoryProvider<SyncService>(
          create: (context) => SyncService(
            transactionRepository: context.read<TransactionRepositoryImpl>(),
            connectivityService: context.read<ConnectivityService>(),
          )..initialize(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Your existing BLoCs...
          BlocProvider<TransactionBloc>(
            create: (context) => TransactionBloc(
              transactionRepository: context.read<TransactionRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          // Your app configuration...
        ),
      ),
    );
  }
}
```

### Step 3: Add Sync Status Indicator (Optional but Recommended)

Create a widget to show sync status in your UI:

```dart
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final syncService = context.read<SyncService>();

    return StreamBuilder<SyncStatus>(
      stream: syncService.syncStatusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final status = snapshot.data!;

        if (status.isInProgress) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Syncing ${status.syncedCount}/${status.totalCount}...',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (status.hasFailures) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '${status.failedCount} transactions failed to sync',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}
```

Add this widget to your AppBar or transaction list:

```dart
AppBar(
  title: const Text('Transactions'),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(40),
    child: SyncStatusIndicator(),
  ),
)
```

### Step 4: Add Offline Indicator

Show users when they're offline:

```dart
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectivityService = context.read<ConnectivityService>();

    return StreamBuilder<bool>(
      stream: connectivityService.connectionStream,
      initialData: connectivityService.isConnected,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;

        if (isOnline) return const SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.red.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'Offline - Changes will sync when online',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Step 5: Update Add Transaction Page (Optional UI Enhancement)

You can show a message when transaction is saved offline:

```dart
// In your add transaction success handler:
if (!await connectivityService.checkConnection()) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Transaction saved offline. Will sync when online.'),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 3),
    ),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Transaction added successfully!'),
      backgroundColor: Colors.green,
    ),
  );
}
```

## ✅ How It Works

1. **User Creates Transaction**:

   - If **online**: Directly saves to Firebase
   - If **offline**: Saves to local SQLite database with 'pending' status

2. **Automatic Sync**:

   - ConnectivityService monitors network status
   - When connection is restored, SyncService automatically triggers
   - Pending transactions are uploaded to Firebase
   - Successfully synced transactions are removed from local DB

3. **Retry Logic**:

   - Failed syncs are retried up to 3 times
   - Transactions that fail all retries are marked as 'failed'
   - Users can manually retry failed transactions

4. **Data Display**:
   - When online: Shows Firebase data
   - When offline: Shows pending local transactions
   - Seamless switching between sources

## 🔧 Configuration Options

### Adjust Maximum Retries

In `sync_service.dart`:

```dart
static const int maxRetries = 3; // Change to your preference
```

### Adjust Sync Behavior

You can trigger manual sync:

```dart
final syncService = context.read<SyncService>();
await syncService.syncPendingTransactions();
```

### Clear Failed Transactions

```dart
final offlineRepo = context.read<OfflineTransactionRepository>();

// Retry a failed transaction
await offlineRepo.retryFailedTransaction(localId);

// Or delete it
await offlineRepo.deletePendingTransaction(localId);
```

## 🐛 Troubleshooting

### Transactions Not Syncing?

1. Check connectivity service is initialized:

```dart
final isOnline = await connectivityService.checkConnection();
print('Connected: $isOnline');
```

2. Check pending transactions:

```dart
final pending = await offlineRepo.getPendingTransactions();
print('Pending: ${pending.length}');
```

3. Manually trigger sync:

```dart
await syncService.syncPendingTransactions();
```

### Database Issues?

Clear database for testing:

```dart
await LocalDatabase.clearAllData();
```

## 📊 Testing

### Test Offline Mode

1. Turn off WiFi/data on device
2. Create a transaction
3. Verify it appears in the list
4. Turn on WiFi/data
5. Verify sync happens automatically
6. Check Firebase for the transaction

### Test Failed Sync

1. Create transaction offline
2. Force error in Firebase rules (temporarily)
3. Turn on connection
4. Verify retry logic works
5. Fix Firebase rules
6. Verify eventual sync success

## 🎉 Benefits

✅ **Works Offline**: Users can create transactions anytime, anywhere
✅ **Automatic Sync**: No manual intervention needed
✅ **Reliable**: Retry logic ensures data isn't lost
✅ **Fast UX**: Optimistic updates make app feel instant
✅ **Resilient**: Falls back gracefully if Firebase is down
✅ **Transparent**: Users know when they're offline and when syncing

## 📝 Notes

- **Attachments**: File uploads still require internet connection
- **Updates/Deletes**: Currently require online connection (can be extended)
- **Categories**: Uses default list when offline
- **Conflicts**: Last-write-wins strategy (can be customized)

## 🚀 Next Steps (Optional Enhancements)

1. **Offline Updates**: Add support for updating transactions offline
2. **Offline Deletes**: Queue deletions for sync
3. **Conflict Resolution**: Implement merge strategies for conflicts
4. **Attachment Queue**: Queue attachment uploads for sync
5. **Background Sync**: Use WorkManager for periodic sync
6. **Encryption**: Encrypt local database for security

---

**Need Help?** Check the inline documentation in each service file for detailed method explanations.
