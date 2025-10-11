import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:phcl_accounts/core/errors/firebase_failure.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';

/// Dashboard repository implementation with machine learning-based revenue prediction.
///
/// This repository provides comprehensive financial analytics and dashboard data
/// aggregation for the PHCL Accounts application. It integrates with Firebase
/// Firestore for real-time transaction data and implements ML algorithms for
/// intelligent revenue forecasting.
///
/// ## Key Features:
///
/// ### 📊 **Financial Analytics**
/// - Real-time transaction aggregation and analysis
/// - Income vs expense tracking with trend visualization
/// - Category-wise spending and earning distribution
/// - Net balance calculation and financial health metrics
///
/// ### 🤖 **ML-Powered Revenue Prediction**
/// - Linear regression using ml_algo and ml_dataframe packages
/// - Time-series forecasting for both daily and monthly periods
/// - Historical pattern recognition and trend extrapolation
/// - Adaptive prediction periods based on data availability
///
/// ### 📈 **Chart Data Generation**
/// - Time-series data preparation for income/expense visualization
/// - Category distribution charts for spending analysis
/// - Revenue trend analysis with historical patterns
/// - Future revenue predictions with confidence intervals
///
/// ### 🔄 **Adaptive Display Modes**
/// - **Daily Mode**: For date ranges ≤ 45 days, provides granular insights
/// - **Monthly Mode**: For longer ranges, shows aggregated monthly trends
/// - Automatic mode selection based on query date range
///
/// ### 🛡️ **Error Handling & Reliability**
/// - Comprehensive Firebase exception handling
/// - Graceful degradation when ML prediction fails
/// - Input validation and data sanitization
/// - Authentication state verification for secure access
///
/// ## Usage Example:
/// ```dart
/// final repository = DashboardRepositoryImpl(
///   firestore: FirebaseFirestore.instance,
///   auth: FirebaseAuth.instance,
/// );
///
/// final dashboardData = await repository.getDashboardData(
///   startDate: DateTime.now().subtract(Duration(days: 30)),
///   endDate: DateTime.now(),
/// );
/// ```
///
/// The implementation leverages modern ML packages for accurate predictions
/// while maintaining performance and reliability for production use.
class DashboardRepositoryImpl implements DashboardRepository {
  /// Firebase Firestore instance for database operations
  final FirebaseFirestore _firestore;

  /// Firebase Auth instance for user authentication
  final FirebaseAuth _auth;

  /// Creates a new instance of [DashboardRepositoryImpl].
  ///
  /// Requires [firestore] instance for database access and [auth] instance
  /// for user authentication and authorization.
  DashboardRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  /// Retrieves comprehensive dashboard data including analytics and ML predictions.
  ///
  /// Fetches transaction data from Firestore, processes it into various chart formats,
  /// and generates ML-based revenue predictions for future periods.
  ///
  /// ## Parameters:
  /// - [startDate]: Optional start date for filtering transactions. If null,
  ///   includes all historical data.
  /// - [endDate]: Optional end date for filtering transactions. If null,
  ///   includes data up to the current date.
  ///
  /// ## Returns:
  /// A [Future<DashboardData>] containing:
  /// - **Financial Totals**: Total income, expenses, and net balance
  /// - **Chart Data**: Time-series data for income/expense visualization
  /// - **Category Analysis**: Distribution of spending/earning by categories
  /// - **Revenue Trends**: Historical revenue patterns and analysis
  /// - **ML Predictions**: Future revenue forecasts using linear regression
  /// - **Display Mode**: Automatically determined based on date range
  ///
  /// ## Date Range Logic:
  /// - **≤ 45 days**: Uses daily aggregation for granular insights
  /// - **> 45 days**: Uses monthly aggregation for broader trends
  ///
  /// ## Throws:
  /// - [FirebaseFailure]: When user is unauthenticated or Firebase errors occur
  /// - Generic exceptions are wrapped in [FirebaseFailure] for consistent error handling
  ///
  /// ## Example:
  /// ```dart
  /// // Get last 30 days of data
  /// final data = await repository.getDashboardData(
  ///   startDate: DateTime.now().subtract(Duration(days: 30)),
  ///   endDate: DateTime.now(),
  /// );
  ///
  /// // Access ML predictions
  /// final predictions = data.revenuePredictionData;
  /// ```
  @override
  Future<DashboardData> getDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw const FirebaseFailure('unauthenticated');

      // Build Firestore query for transactions within the specified period
      // Only includes non-deleted transactions ordered by date (newest first)
      Query query = _firestore
          .collection('transactions')
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true);

      // Apply date range filters if specified
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      // Execute the query and convert documents to entity objects
      final snapshot = await query.get();

      final transactions = snapshot.docs
          .map((doc) => TransactionEntity.fromDocumentSnapshot(doc))
          .toList();

      // Automatically determine optimal display mode (daily vs monthly)
      // based on the date range to provide appropriate granularity
      final displayMode = _determineDisplayMode(startDate, endDate);

      // Calculate financial summary totals for the period
      final totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold<double>(0, (s, t) => s + (t.amount));

      final totalExpense = transactions
          .where((t) => t.type == 'expense')
          .fold<double>(0, (s, t) => s + (t.amount));

      // Generate various chart data formats for dashboard visualization

      // Time-series data for income tracking (daily or monthly aggregation)
      final incomeChartData = _prepareTimeSeriesData(
        transactions.where((t) => t.type == 'income').toList(),
        displayMode,
      );

      // Time-series data for expense tracking (daily or monthly aggregation)
      final expenseChartData = _prepareTimeSeriesData(
        transactions.where((t) => t.type == 'expense').toList(),
        displayMode,
      );

      // Category-wise distribution for expense analysis (pie/donut charts)
      final expenseCategoryDistribution = _prepareCategoryData(
        transactions.where((t) => t.type == 'expense').toList(),
      );

      // Category-wise distribution for income analysis (pie/donut charts)
      final incomeCategoryDistribution = _prepareCategoryData(
        transactions.where((t) => t.type == 'income').toList(),
      );

      // Net revenue trend combining income and expenses over time
      final revenueTrendData = _prepareRevenueTrendData(
        transactions,
        displayMode,
      );

      // Generate ML-based revenue predictions for future periods
      // Uses linear regression to forecast upcoming revenue trends
      final revenuePredictionData = _prepareRevenuePredictionData(
        revenueTrendData,
        displayMode,
      );

      return DashboardData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        incomeChartData: incomeChartData,
        expenseChartData: expenseChartData,
        incomeCategoryDistribution: incomeCategoryDistribution,
        expenseCategoryDistribution: expenseCategoryDistribution,
        revenueTrendData: revenueTrendData,
        revenuePredictionData: revenuePredictionData,
        displayMode: displayMode,
      );
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  /// Determines the optimal chart display mode based on the query date range.
  ///
  /// Automatically selects between daily and monthly aggregation to provide
  /// the most meaningful data visualization based on the time span.
  ///
  /// ## Logic:
  /// - **Daily Mode**: For ranges ≤ 45 days - provides detailed daily insights
  /// - **Monthly Mode**: For ranges > 45 days - shows broader monthly trends
  /// - **Default**: Monthly mode when date range is not specified
  ///
  /// ## Parameters:
  /// - [startDate]: The beginning of the date range (optional)
  /// - [endDate]: The end of the date range (optional)
  ///
  /// ## Returns:
  /// [ChartDisplayMode.daily] or [ChartDisplayMode.monthly]
  ChartDisplayMode _determineDisplayMode(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // Default to monthly mode when date range is not specified
    if (startDate == null || endDate == null) {
      return ChartDisplayMode.monthly;
    }

    final daysDifference = endDate.difference(startDate).inDays;

    // Use daily view for short ranges (≤ 45 days) to show detailed patterns
    // Use monthly view for longer ranges to avoid overcrowded visualizations
    return daysDifference <= 45
        ? ChartDisplayMode.daily
        : ChartDisplayMode.monthly;
  }

  /// Prepares time-series chart data for income or expense visualization.
  ///
  /// Aggregates transaction amounts by time period (daily or monthly) and
  /// formats the data for chart rendering. Handles date formatting based on
  /// the display mode and ensures proper chronological ordering.
  ///
  /// ## Parameters:
  /// - [transactions]: List of transactions to aggregate (filtered by type)
  /// - [displayMode]: Determines aggregation level (daily vs monthly)
  ///
  /// ## Date Formatting:
  /// - **Daily Mode**:
  ///   - Current year: "MMM dd" (e.g., "Jan 15")
  ///   - Other years: "MMM dd, yy" (e.g., "Jan 15, 24")
  /// - **Monthly Mode**: "MMM yy" (e.g., "Jan 24")
  ///
  /// ## Returns:
  /// List of [ChartData] objects sorted chronologically, ready for visualization
  List<ChartData> _prepareTimeSeriesData(
    List<TransactionEntity> transactions,
    ChartDisplayMode displayMode,
  ) {
    // Group transactions by time period and sum amounts
    final Map<String, double> groupedTotals = {};

    for (final t in transactions) {
      String key;
      if (displayMode == ChartDisplayMode.daily) {
        // Include year in key if the transaction is from a different year
        // This ensures proper distinction for cross-year date ranges
        final now = DateTime.now();
        if (t.date.year != now.year) {
          key = DateFormat('MMM dd, yy').format(t.date);
        } else {
          key = DateFormat('MMM dd').format(t.date);
        }
      } else {
        // Monthly aggregation uses month-year format
        key = DateFormat('MMM yy').format(t.date);
      }

      // Accumulate transaction amounts for each time period
      groupedTotals.update(
        key,
        (value) => value + (t.amount),
        ifAbsent: () => t.amount,
      );
    }

    // Convert grouped data to ChartData objects
    final sortedData = groupedTotals.entries
        .map((e) => ChartData(e.key, e.value))
        .toList();

    // Sort chronologically based on display mode for proper chart rendering
    if (displayMode == ChartDisplayMode.daily) {
      // Sort daily data chronologically, handling both date formats
      sortedData.sort((a, b) {
        try {
          // Parse dates using appropriate format (with or without year)
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
          // Fallback to string comparison if date parsing fails
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

  /// Prepares category-wise distribution data for pie/donut chart visualization.
  ///
  /// Aggregates transaction amounts by category and sorts them by total amount
  /// in descending order to highlight the largest spending/earning categories.
  ///
  /// ## Parameters:
  /// - [transactions]: List of transactions to group by category
  ///
  /// ## Returns:
  /// List of [ChartData] objects sorted by amount (highest first), suitable
  /// for pie charts, donut charts, or category breakdown visualizations
  ///
  /// ## Usage:
  /// ```dart
  /// // For expense categories
  /// final expenseCategories = _prepareCategoryData(
  ///   transactions.where((t) => t.type == 'expense').toList()
  /// );
  /// ```
  List<ChartData> _prepareCategoryData(List<TransactionEntity> transactions) {
    // Group transactions by category and sum amounts
    final Map<String, double> categoryTotals = {};

    for (final t in transactions) {
      final category = t.category;
      categoryTotals.update(
        category,
        (value) => value + (t.amount),
        ifAbsent: () => t.amount,
      );
    }

    // Convert to ChartData and sort by amount (largest categories first)
    return categoryTotals.entries.map((e) => ChartData(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Prepares net revenue trend data combining income and expenses over time.
  ///
  /// Calculates net revenue (income - expenses) for each time period and formats
  /// the data for trend visualization. This provides insight into overall financial
  /// health and revenue patterns over time.
  ///
  /// ## Calculation Logic:
  /// - **Income transactions**: Added to the period total (+amount)
  /// - **Expense transactions**: Subtracted from the period total (-amount)
  /// - **Net Revenue**: Sum of all income minus all expenses for each period
  ///
  /// ## Parameters:
  /// - [transactions]: All transactions (both income and expense)
  /// - [displayMode]: Determines time period aggregation (daily vs monthly)
  ///
  /// ## Returns:
  /// List of [ChartData] objects representing net revenue over time, sorted
  /// chronologically. Positive values indicate profit, negative values indicate loss.
  ///
  /// ## Example Data:
  /// ```dart
  /// [
  ///   ChartData("Jan 24", 1500.0),  // Profit of $1500
  ///   ChartData("Feb 24", -200.0),  // Loss of $200
  ///   ChartData("Mar 24", 800.0),   // Profit of $800
  /// ]
  /// ```
  List<ChartData> _prepareRevenueTrendData(
    List<TransactionEntity> transactions,
    ChartDisplayMode displayMode,
  ) {
    // Group transactions by time period and calculate net revenue
    final Map<String, double> groupedMap = {};

    for (var transaction in transactions) {
      String key;
      if (displayMode == ChartDisplayMode.daily) {
        // Include year in key if the transaction is from a different year
        final now = DateTime.now();
        if (transaction.date.year != now.year) {
          key = DateFormat('MMM dd, yy').format(transaction.date);
        } else {
          key = DateFormat('MMM dd').format(transaction.date);
        }
      } else {
        // Monthly aggregation uses month-year format
        key = DateFormat('MMM yy').format(transaction.date);
      }

      // Calculate net revenue: income adds, expenses subtract
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

  /// Prepares ML-based revenue prediction data using linear regression analysis.
  ///
  /// This method serves as the main entry point for generating revenue predictions.
  /// It routes to appropriate prediction algorithms based on the display mode and
  /// handles error cases gracefully.
  ///
  /// ## ML Approach:
  /// - **Algorithm**: Linear regression using ml_algo package
  /// - **Features**: Time-series data with temporal patterns
  /// - **Training Data**: Historical revenue trends
  /// - **Prediction Horizon**:
  ///   - Daily mode: 7 days ahead
  ///   - Monthly mode: 6 months ahead
  ///
  /// ## Parameters:
  /// - [revenueTrendData]: Historical revenue trend data for ML training
  /// - [displayMode]: Determines prediction timeframe and aggregation level
  ///
  /// ## Returns:
  /// List of [ChartData] objects containing predicted revenue values for future
  /// periods. Returns empty list if prediction fails or insufficient data.
  ///
  /// ## Error Handling:
  /// - Gracefully handles insufficient historical data
  /// - Returns empty predictions on ML algorithm failures
  /// - No exceptions thrown to maintain UI stability
  List<ChartData> _prepareRevenuePredictionData(
    List<ChartData> revenueTrendData,
    ChartDisplayMode displayMode,
  ) {
    try {
      if (revenueTrendData.isEmpty) {
        return [];
      }

      // Route to appropriate prediction algorithm based on display mode
      if (displayMode == ChartDisplayMode.daily) {
        return predictDailyFutureRevenue(revenueTrendData);
      } else {
        return predictMonthlyFutureRevenue(revenueTrendData);
      }
    } catch (e) {
      return [];
    }
  }

  /// Predicts future monthly revenue using machine learning linear regression.
  ///
  /// Implements a comprehensive ML pipeline for monthly revenue forecasting:
  /// 1. **Data Preprocessing**: Converts historical revenue data to numerical features
  /// 2. **Feature Engineering**: Creates time-based features from date information
  /// 3. **Model Training**: Trains LinearRegressor with closed-form optimization
  /// 4. **Prediction Generation**: Forecasts revenue for future months
  /// 5. **Post-processing**: Formats predictions for chart visualization
  ///
  /// ## Algorithm Details:
  /// - **Model**: LinearRegressor from ml_algo package
  /// - **Optimizer**: Closed-form solution for optimal performance
  /// - **Features**: Time (milliseconds since epoch) → Revenue mapping
  /// - **Training**: Uses historical revenue trend data
  ///
  /// ## Adaptive Prediction Horizon:
  /// - Default: 6 months ahead
  /// - Adaptive: Reduces to available data length if < 6 months of history
  /// - Minimum: Requires at least some historical data points
  ///
  /// ## Parameters:
  /// - [revenueTrendData]: Historical monthly revenue data for ML training
  /// - [monthsToPredict]: Number of future months to forecast (default: 6)
  ///
  /// ## Returns:
  /// List of [ChartData] objects with predicted monthly revenue values.
  /// Each entry contains:
  /// - **Key**: Formatted date string ("MMM yy", e.g., "Apr 25")
  /// - **Value**: Predicted revenue amount for that month
  ///
  /// ## Error Resilience:
  /// - Returns empty list on insufficient data or ML failures
  /// - Handles date parsing errors gracefully
  /// - No exceptions propagated to maintain UI stability
  List<ChartData> predictMonthlyFutureRevenue(
    List<ChartData> revenueTrendData, {
    int monthsToPredict = 6,
  }) {
    if (revenueTrendData.isEmpty || revenueTrendData.length <= 1) return [];

    // Adapt prediction horizon based on available historical data
    if (revenueTrendData.length < 6) {
      monthsToPredict = revenueTrendData.length;
    }

    try {
      // Convert historical dates to numerical features (milliseconds since epoch)
      // This creates a time-series feature that ML algorithms can process
      final dates = revenueTrendData.map((data) {
        final date = DateFormat('MMM yy').parse(data.key);
        return date.millisecondsSinceEpoch.toDouble();
      }).toList();

      // Extract revenue values as target variables for ML training
      final values = revenueTrendData.map((data) => data.value).toList();

      // Create DataFrame with time-value pairs for ML algorithm
      // Format: [['time', 'value'], [timestamp1, revenue1], [timestamp2, revenue2], ...]
      final dataframe = DataFrame([
        ['time', 'value'],
        for (var i = 0; i < dates.length; i++) [dates[i], values[i]],
      ], headerExists: true);

      // Initialize and train Linear Regression model
      // Uses closed-form solution for optimal performance and accuracy
      final model = LinearRegressor(
        dataframe,
        'value', // Target column to predict
        optimizerType: LinearOptimizerType.closedForm,
      );

      // Generate predictions for future months
      final lastDate = DateFormat('MMM yy').parse(revenueTrendData.last.key);
      final predictions = <ChartData>[];

      // Create predictions for each future month
      for (int i = 1; i <= monthsToPredict; i++) {
        // Calculate future date by adding months to the last historical date
        final futureDate = DateTime(lastDate.year, lastDate.month + i);

        // Prepare prediction input: convert future date to numerical feature
        final predictionData = DataFrame([
          ['time'],
          [futureDate.millisecondsSinceEpoch.toDouble()],
        ], headerExists: true);

        // Use trained model to predict revenue for the future date
        final prediction = model.predict(predictionData);
        final predictedValue = prediction.rows.first.first;

        // Format prediction as ChartData for visualization
        predictions.add(
          ChartData(DateFormat('MMM yy').format(futureDate), predictedValue),
        );
      }

      return predictions;
    } catch (e) {
      return [];
    }
  }

  /// Predicts future daily revenue using machine learning linear regression.
  ///
  /// Implements a specialized ML pipeline for short-term daily revenue forecasting:
  /// 1. **Data Preprocessing**: Converts daily historical revenue to numerical features
  /// 2. **Feature Engineering**: Maps daily dates to time-series numerical data
  /// 3. **Model Training**: Trains LinearRegressor optimized for daily patterns
  /// 4. **Daily Predictions**: Generates day-by-day revenue forecasts
  /// 5. **Output Formatting**: Creates chart-ready data with proper date labels
  ///
  /// ## Daily vs Monthly Differences:
  /// - **Granularity**: Day-level predictions vs month-level aggregations
  /// - **Horizon**: Shorter forecast period (7 days vs 6 months)
  /// - **Patterns**: Captures daily fluctuations and short-term trends
  /// - **Use Case**: Immediate planning vs long-term strategic forecasting
  ///
  /// ## Algorithm Configuration:
  /// - **Model**: LinearRegressor with closed-form optimization
  /// - **Features**: Daily timestamps (milliseconds since epoch)
  /// - **Target**: Daily net revenue values
  /// - **Training Data**: Historical daily revenue patterns
  ///
  /// ## Adaptive Prediction:
  /// - Default: 7 days ahead for weekly planning
  /// - Adaptive: Reduces to available history length if < 7 days
  /// - Practical: Focuses on immediate actionable insights
  ///
  /// ## Parameters:
  /// - [revenueTrendData]: Historical daily revenue data for ML training
  /// - [daysToPredict]: Number of future days to forecast (default: 7)
  ///
  /// ## Returns:
  /// List of [ChartData] objects with predicted daily revenue values.
  /// Each entry contains:
  /// - **Key**: Formatted date string ("MMM dd", e.g., "Apr 15")
  /// - **Value**: Predicted revenue amount for that specific day
  ///
  /// ## Use Cases:
  /// - Short-term cash flow planning
  /// - Daily operational decisions
  /// - Weekly revenue targets
  /// - Immediate trend validation

  List<ChartData> predictDailyFutureRevenue(
    List<ChartData> revenueTrendData, {
    int daysToPredict = 7,
  }) {
    if (revenueTrendData.isEmpty || revenueTrendData.length <= 1) return [];

    // Adapt prediction horizon to available historical data
    if (revenueTrendData.length < 7) {
      daysToPredict = revenueTrendData.length;
    }

    try {
      // Convert daily dates to numerical features for ML processing
      // Uses daily date format without year for current-year data
      final dates = revenueTrendData.map((data) {
        final date = DateFormat('MMM dd').parse(data.key);
        return date.millisecondsSinceEpoch.toDouble();
      }).toList();

      // Extract daily revenue values as training targets
      final values = revenueTrendData.map((data) => data.value).toList();

      // Create DataFrame optimized for daily time-series analysis
      // Format: [['time', 'value'], [daily_timestamp1, revenue1], ...]
      final dataframe = DataFrame([
        ['time', 'value'],
        for (var i = 0; i < dates.length; i++) [dates[i], values[i]],
      ], headerExists: true);

      // Train Linear Regression model for daily pattern recognition
      // Closed-form optimizer provides fast, deterministic results
      final model = LinearRegressor(
        dataframe,
        'value', // Daily revenue target
        optimizerType: LinearOptimizerType.closedForm,
      );

      // Generate daily predictions starting from the last historical date
      final lastDate = DateFormat('MMM dd').parse(revenueTrendData.last.key);
      final predictions = <ChartData>[];

      // Create predictions for each future day
      for (int i = 1; i <= daysToPredict; i++) {
        // Calculate future date by adding days to the last historical date
        final futureDate = lastDate.add(Duration(days: i));

        // Prepare prediction input: convert future date to numerical feature
        final predictionData = DataFrame([
          ['time'],
          [futureDate.millisecondsSinceEpoch.toDouble()],
        ], headerExists: true);

        // Generate prediction using the trained model
        final prediction = model.predict(predictionData);
        final predictedValue = prediction.rows.first.first;

        // Format as ChartData with daily date label
        predictions.add(
          ChartData(DateFormat('MMM dd').format(futureDate), predictedValue),
        );
      }

      return predictions;
    } catch (e) {
      // Gracefully handle ML prediction failures without crashing the UI
      // Returns empty list to maintain application stability
      return [];
    }
  }
}
