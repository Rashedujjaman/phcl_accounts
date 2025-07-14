import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'dart:io';

abstract class TransactionRepository {
  Future<void> addTransaction(TransactionEntity transaction);
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type
  });
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
  Future<List<String>> getCategories({required String type});
  Future<String> uploadAttachment(File file);
  Future<void> deleteAttachment(String url);
}