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

      // Determine display mode based on date range
      final displayMode = _determineDisplayMode(startDate, endDate);

      // Calculate totals
      final totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold<double>(0, (s, t) => s + (t.amount));

      final totalExpense = transactions
          .where((t) => t.type == 'expense')
          .fold<double>(0, (s, t) => s + (t.amount));

      // Prepare chart data based on display mode
      final incomeChartData = _prepareTimeSeriesData(
        transactions.where((t) => t.type == 'income').toList(),
        displayMode,
      );

      final expenseChartData = _prepareTimeSeriesData(
        transactions.where((t) => t.type == 'expense').toList(),
        displayMode,
      );

      final expenseCategoryDistribution = _prepareCategoryData(
        transactions.where((t) => t.type == 'expense').toList(),
      );

      final incomeCategoryDistribution = _prepareCategoryData(
        transactions.where((t) => t.type == 'income').toList(),
      );

      final revenueTrendData = _prepareRevenueTrendData(transactions, displayMode);

      return DashboardData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        incomeChartData: incomeChartData,
        expenseChartData: expenseChartData,
        incomeCategoryDistribution: incomeCategoryDistribution,
        expenseCategoryDistribution: expenseCategoryDistribution,
        revenueTrendData: revenueTrendData,
        displayMode: displayMode,
      );
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  /// Determines the appropriate display mode based on the date range
  ChartDisplayMode _determineDisplayMode(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return ChartDisplayMode.monthly;
    }
    
    final daysDifference = endDate.difference(startDate).inDays;
    
    // Use daily view for ranges <= 45 days, monthly for longer ranges
    return daysDifference <= 45 ? ChartDisplayMode.daily : ChartDisplayMode.monthly;
  }

  List<ChartData> _prepareTimeSeriesData(
    List<TransactionEntity> transactions, 
    ChartDisplayMode displayMode,
  ) {
    final Map<String, double> groupedTotals = {};

    for (final t in transactions) {
      String key;
      if (displayMode == ChartDisplayMode.daily) {
        // Include year if the range spans multiple years
        final now = DateTime.now();
        if (t.date.year != now.year) {
          key = DateFormat('MMM dd, yy').format(t.date);
        } else {
          key = DateFormat('MMM dd').format(t.date);
        }
      } else {
        key = DateFormat('MMM yy').format(t.date);
      }
      
      groupedTotals.update(
        key,
        (value) => value + (t.amount),
        ifAbsent: () => t.amount,
      );
    }

    final sortedData = groupedTotals.entries
        .map((e) => ChartData(e.key, e.value))
        .toList();

    // Sort based on display mode
    if (displayMode == ChartDisplayMode.daily) {
      sortedData.sort((a, b) {
        try {
          // Try both formats for daily view
          DateTime dateA, dateB;
          try {
            dateA = DateFormat('MMM dd, yy').parse(a.key);
          } catch (e) {
            dateA = DateFormat('MMM dd').parse(a.key);
          }
          try {
            dateB = DateFormat('MMM dd, yy').parse(b.key);
          } catch (e) {
            dateB = DateFormat('MMM dd').parse(b.key);
          }
          return dateA.compareTo(dateB);
        } catch (e) {
          return a.key.compareTo(b.key);
        }
      });
    } else {
      sortedData.sort((a, b) {
        try {
          final dateA = DateFormat('MMM yy').parse(a.key);
          final dateB = DateFormat('MMM yy').parse(b.key);
          return dateA.compareTo(dateB);
        } catch (e) {
          return a.key.compareTo(b.key);
        }
      });
    }

    return sortedData;
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

  List<ChartData> _prepareRevenueTrendData(
    List<TransactionEntity> transactions,
    ChartDisplayMode displayMode,
  ) {
    final Map<String, double> groupedMap = {};

    for (var transaction in transactions) {
      String key;
      if (displayMode == ChartDisplayMode.daily) {
        // Include year if the range spans multiple years
        final now = DateTime.now();
        if (transaction.date.year != now.year) {
          key = DateFormat('MMM dd, yy').format(transaction.date);
        } else {
          key = DateFormat('MMM dd').format(transaction.date);
        }
      } else {
        key = DateFormat('MMM yy').format(transaction.date);
      }
      
      groupedMap.update(
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
    var sortedData = groupedMap.entries
        .map((e) => ChartData(e.key, e.value))
        .toList();

    // Sort based on display mode
    if (displayMode == ChartDisplayMode.daily) {
      sortedData.sort((a, b) {
        try {
          // Try both formats for daily view
          DateTime dateA, dateB;
          try {
            dateA = DateFormat('MMM dd, yy').parse(a.key);
          } catch (e) {
            dateA = DateFormat('MMM dd').parse(a.key);
          }
          try {
            dateB = DateFormat('MMM dd, yy').parse(b.key);
          } catch (e) {
            dateB = DateFormat('MMM dd').parse(b.key);
          }
          return dateA.compareTo(dateB);
        } catch (e) {
          return a.key.compareTo(b.key);
        }
      });
    } else {
      sortedData.sort((a, b) {
        try {
          final dateA = DateFormat('MMM yy').parse(a.key);
          final dateB = DateFormat('MMM yy').parse(b.key);
          return dateA.compareTo(dateB);
        } catch (e) {
          return a.key.compareTo(b.key);
        }
      });
    }

    return sortedData;
  }
}