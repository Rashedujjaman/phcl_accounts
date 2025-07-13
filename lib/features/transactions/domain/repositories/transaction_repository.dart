import 'dart:io';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entry.dart';

abstract class TransactionRepository {
  /// Fetches all transactions.
  Future<List<TransactionEntity>> getTransactions();

  /// Fetches a single transaction by its [id].
  // Future<TransactionEntity?> getTransactionById(String id);

  /// Adds a new [transaction].
  Future<void> addTransaction(TransactionEntity transaction, File? attachment);

  /// Updates an existing [transaction].
  // Future<void> updateTransaction(TransactionEntity transaction);

  /// Deletes a transaction by its [id].
  // Future<void> deleteTransaction(String id);
}

// You may need to import your Transaction model:
// import '../entities/transaction.dart';