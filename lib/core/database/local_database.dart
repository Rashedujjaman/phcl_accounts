import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local database service for offline storage and sync queue management.
///
/// Provides SQLite database access for:
/// - **Pending Transactions**: Stores transactions created offline
/// - **Sync Queue**: Tracks operations waiting for network sync
/// - **Offline Cache**: Local copy of synced data for offline access
///
/// The database is initialized on first access and handles schema migrations.
class LocalDatabase {
  static Database? _database;
  static const String _databaseName = 'phcl_accounts.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String pendingTransactionsTable = 'pending_transactions';
  static const String syncQueueTable = 'sync_queue';

  /// Gets the database instance, creating it if necessary.
  ///
  /// Uses singleton pattern to ensure only one database connection exists.
  /// Initializes database schema on first access.
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the SQLite database with required tables.
  ///
  /// Creates:
  /// - pending_transactions: Stores offline transaction data
  /// - sync_queue: Manages pending sync operations
  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates database tables on first installation.
  ///
  /// **pending_transactions table**:
  /// - Stores complete transaction data for offline creation
  /// - Includes local_id for tracking before Firebase sync
  /// - sync_status: 'pending', 'syncing', 'failed'
  ///
  /// **sync_queue table**:
  /// - Tracks all pending sync operations
  /// - Supports different operation types (add, update, delete)
  /// - Records retry attempts and error messages
  static Future<void> _createTables(Database db, int version) async {
    // Table for storing pending transactions
    await db.execute('''
      CREATE TABLE $pendingTransactionsTable (
        local_id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        amount REAL NOT NULL,
        client_id TEXT,
        contact_no TEXT,
        note TEXT,
        attachment_url TEXT,
        attachment_type TEXT,
        attachment_local_path TEXT,
        transact_by TEXT,
        created_by TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        firebase_id TEXT,
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        last_sync_attempt INTEGER
      )
    ''');

    // Table for sync queue management
    await db.execute('''
      CREATE TABLE $syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        error_message TEXT,
        last_attempt INTEGER
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_pending_transactions_sync_status 
      ON $pendingTransactionsTable(sync_status)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_status 
      ON $syncQueueTable(status)
    ''');
  }

  /// Handles database schema upgrades for future versions.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle future schema migrations here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE pending_transactions ADD COLUMN new_field TEXT');
    // }
  }

  /// Closes the database connection.
  ///
  /// Should be called when the app is being disposed to free resources.
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clears all data from the database.
  ///
  /// Used for testing or user logout scenarios.
  /// **Warning**: This is a destructive operation!
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(pendingTransactionsTable);
    await db.delete(syncQueueTable);
  }
}
