import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

      final expenseCategoryDistribution = _prepareCategoryData(
        transactions.where((t) => t.type == 'expense').toList(),
      );

      final incomeCategoryDistribution = _prepareCategoryData(
        transactions.where((t) => t.type == 'income').toList(),
      );

      final revenueTrendData = _prepareRevenueTrendData(transactions);

      return DashboardData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        incomeChartData: incomeChartData,
        expenseChartData: expenseChartData,
        incomeCategoryDistribution: incomeCategoryDistribution,
        expenseCategoryDistribution: expenseCategoryDistribution,
        revenueTrendData: revenueTrendData,
      );
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  List<ChartData> _prepareTimeSeriesData(List<TransactionEntity> transactions) {
    final Map<String, double> dailyTotals = {};

    for (final t in transactions) {
      final key = DateFormat('MMM yy').format(t.date);
      dailyTotals.update(
        key,
        (value) => value + (t.amount),
        ifAbsent: () => t.amount,
      );
    }

    return dailyTotals.entries
        .map((e) => ChartData(e.key, e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<ChartData> _prepareCategoryData(List<TransactionEntity> transactions) {
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
        .map((e) => ChartData(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<ChartData> _prepareRevenueTrendData(List<TransactionEntity> transactions) {
    final Map<String, double> monthlyMap = {};

    for (var transaction in transactions) {
      final key = DateFormat('MMM yy').format(transaction.date);
      monthlyMap.update(
        key,
        (val) => transaction.type == 'income'
            ? val + transaction.amount
            : val - transaction.amount,
        ifAbsent: () => transaction.type == 'income'
            ? transaction.amount
            : -transaction.amount,
      );
    }

    // Convert to list and sort by date
    var sortedData = monthlyMap.entries
        .map((e) => ChartData(e.key, e.value))
        .toList()
      ..sort((a, b) => DateFormat('MMM yy')
          .parse(a.key)
          .compareTo(DateFormat('MMM yy').parse(b.key)));

    return sortedData;
  }
}