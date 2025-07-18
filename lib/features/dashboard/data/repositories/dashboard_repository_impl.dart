import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phcl_accounts/core/errors/firebase_failure.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DashboardRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  @override
  Future<DashboardData> getDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw const FirebaseFailure('unauthenticated');

      // Get all transactions for the period
      Query query = _firestore.collection('transactions')
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      final transactions = snapshot.docs.map((doc) => TransactionEntity.fromDocumentSnapshot(doc)).toList();

      // Calculate totals
      final totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold<double>(0, (s, t) => s + (t.amount));

      final totalExpense = transactions
          .where((t) => t.type == 'expense')
          .fold<double>(0, (s, t) => s + (t.amount));

      // Prepare chart data
      final incomeChartData = _prepareTimeSeriesData(
        transactions.where((t) => t.type == 'income').toList(),
      );

      final expenseChartData = _prepareTimeSeriesData(
        transactions.where((t) => t.type == 'expense').toList(),
      );

      final categoryDistribution = _prepareCategoryData(
        transactions.where((t) => t.type == 'expense').toList(),
      );

      return DashboardData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        incomeChartData: incomeChartData,
        expenseChartData: expenseChartData,
        categoryDistribution: categoryDistribution,
      );
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  List<TransactionChartData> _prepareTimeSeriesData(List<TransactionEntity> transactions) {
    final Map<DateTime, double> dailyTotals = {};

    for (final t in transactions) {
      final date = DateTime(
        t.date.year,
        t.date.month,
        t.date.day,
      );
      dailyTotals.update(
        date,
        (value) => value + (t.amount),
        ifAbsent: () => t.amount,
      );
    }

    return dailyTotals.entries
        .map((e) => TransactionChartData(e.key, e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<CategoryChartData> _prepareCategoryData(List<TransactionEntity> transactions) {
    final Map<String, double> categoryTotals = {};

    for (final t in transactions) {
      final category = t.category;
      categoryTotals.update(
        category,
        (value) => value + (t.amount),
        ifAbsent: () => t.amount,
      );
    }

    return categoryTotals.entries
        .map((e) => CategoryChartData(e.key, e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}