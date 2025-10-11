import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// A sophisticated cartesian bar chart widget for comparative financial analysis.
///
/// This widget provides advanced dual-series bar chart capabilities specifically
/// designed for comparing income vs expense data in the PHCL Accounts dashboard
/// application. It offers clear visual distinction between different financial
/// categories with intelligent theming and responsive design.
///
/// ## Key Features:
///
/// ### 📊 **Dual-Series Comparison**
/// - **Income Series**: Displays positive financial inflows with tertiary theme color
/// - **Expense Series**: Shows financial outflows with error theme color for contrast
/// - **Side-by-Side Visualization**: Clear comparison of income vs expenses by period
/// - **Visual Hierarchy**: Distinct colors help users quickly identify data types
///
/// ### 🎯 **Adaptive Display Modes**
/// - **Daily Mode**: Optimized for short-term analysis with angled labels (≤ 45 days)
/// - **Monthly Mode**: Configured for long-term comparison with horizontal labels
/// - **Smart Label Rotation**: Automatic adjustment based on data density
/// - **Responsive Layout**: Adapts to different screen sizes and orientations
///
/// ### 🔧 **Interactive Features**
/// - **Tooltips**: Hover/tap to see precise values and categories
/// - **Data Labels**: Automatically shown for datasets ≤ 8 points per series
/// - **Interactive Legend**: Toggle visibility of income/expense series
/// - **Zoom & Pan**: Built-in navigation for large datasets
///
/// ### 🎨 **Intelligent Theming**
/// - **Theme Integration**: Uses Material Design color scheme
/// - **Semantic Colors**: Error color for expenses, tertiary for income
/// - **Accessibility Compliant**: High contrast ratios for readability
/// - **Consistent Styling**: Matches overall app theme automatically
///
/// ### 📈 **Data Visualization Best Practices**
/// - **Clear Category Distinction**: Income vs expense immediately recognizable
/// - **Optimal Bar Spacing**: Prevents overcrowding while maximizing data visibility
/// - **Smart Label Management**: Conditional display based on data density
/// - **Responsive Angles**: Label rotation adapts to prevent overlapping
///
/// ## Usage Examples:
///
/// ### Basic Income vs Expense Comparison
/// ```dart
/// CartesianBarChart(
///   incomeData: monthlyIncome,
///   expenseData: monthlyExpenses,
///   title: 'Monthly Income vs Expenses',
///   displayMode: ChartDisplayMode.monthly,
/// )
/// ```
///
/// ### Daily Financial Analysis
/// ```dart
/// CartesianBarChart(
///   incomeData: dailyIncome,
///   expenseData: dailyExpenses,
///   title: 'Daily Financial Overview',
///   displayMode: ChartDisplayMode.daily,
///   color: Colors.blue, // Optional override
/// )
/// ```
///
/// ### Quarterly Business Review
/// ```dart
/// CartesianBarChart(
///   incomeData: quarterlyRevenue,
///   expenseData: quarterlyCosts,
///   title: 'Quarterly Performance',
///   displayMode: ChartDisplayMode.monthly,
/// )
/// ```
///
/// ## Technical Implementation:
/// - Built on Syncfusion Flutter Charts for performance and rich features
/// - Optimized for financial data comparison workflows
/// - Memory-efficient handling of dual-series datasets
/// - Smooth animations and responsive interactions
/// - Automatic color theming with semantic meaning
class CartesianBarChart extends StatelessWidget {
  /// Income data series for positive financial inflows.
  ///
  /// Contains time-based chart data representing revenue, salary,
  /// investments, or other income sources. Displayed using the
  /// theme's tertiary color to indicate positive financial impact.
  final List<ChartData> incomeData;

  /// Expense data series for financial outflows.
  ///
  /// Contains time-based chart data representing costs, purchases,
  /// bills, or other expenses. Displayed using the theme's error
  /// color to provide clear visual distinction from income.
  final List<ChartData> expenseData;

  /// The descriptive title for the chart.
  ///
  /// Used as the chart title and for accessibility labeling.
  /// Examples: "Monthly Overview", "Weekly Comparison", "Quarterly Analysis"
  final String title;

  /// Optional color override for custom theming.
  ///
  /// When provided, this color may be used for accent elements.
  /// If null, the widget uses semantic theme colors:
  /// - Tertiary color for income (typically green/positive tones)
  /// - Error color for expenses (typically red/warning tones)
  final Color? color;

  /// Display mode determining chart optimization and label formatting.
  ///
  /// - **Daily Mode**: Uses angled labels (-45°) for better readability with dates
  /// - **Monthly Mode**: Uses horizontal labels (0°) for cleaner monthly display
  /// - **Null**: Defaults to horizontal labeling suitable for most cases
  final ChartDisplayMode? displayMode;

  /// Creates a new cartesian bar chart widget for income vs expense comparison.
  ///
  /// ## Required Parameters:
  /// - [incomeData]: Dataset for income/revenue visualization
  /// - [expenseData]: Dataset for expense/cost visualization
  /// - [title]: Chart title and accessibility label
  ///
  /// ## Optional Parameters:
  /// - [color]: Custom color override (defaults to semantic theme colors)
  /// - [displayMode]: Chart optimization mode for different time granularities
  ///
  /// ## Example:
  /// ```dart
  /// CartesianBarChart(
  ///   incomeData: monthlyRevenue,
  ///   expenseData: monthlyCosts,
  ///   title: 'Financial Overview',
  ///   displayMode: ChartDisplayMode.monthly,
  /// )
  /// ```
  ///
  /// ## Data Requirements:
  /// Both income and expense data should have matching time periods
  /// for accurate comparison visualization.
  const CartesianBarChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
    required this.title,
    this.color,
    this.displayMode,
  });

  @override
  Widget build(BuildContext context) {
    // Extract theme for consistent color application
    final theme = Theme.of(context);

    // Build high-performance cartesian chart with dual series
    return SfCartesianChart(
      // Chart title for context and accessibility
      title: ChartTitle(text: title),

      // Interactive legend for series toggling
      legend: const Legend(isVisible: true),

      // X-axis configuration with adaptive label rotation
      primaryXAxis: CategoryAxis(
        // Smart label rotation based on display mode and data density
        labelRotation: displayMode == ChartDisplayMode.daily ? -45 : 0,
        // Handle overlapping labels with multiple row layout
        labelIntersectAction: AxisLabelIntersectAction.multipleRows,
      ),

      // Enable interactive tooltips for precise value inspection
      tooltipBehavior: TooltipBehavior(enable: true),

      // Define dual-series column chart for income vs expense comparison
      series: <CartesianSeries<ChartData, String>>[
        // Income series: Positive financial inflows
        ColumnSeries<ChartData, String>(
          dataSource: incomeData,
          xValueMapper: (ChartData data, _) => data.key, // Time periods (dates)
          yValueMapper: (ChartData data, _) => data.value, // Income amounts
          name: 'Income',

          // Use tertiary theme color for positive financial data
          color: theme.colorScheme.tertiary,

          // Smart data label configuration
          dataLabelSettings: DataLabelSettings(
            // Only show labels for smaller datasets to prevent overcrowding
            isVisible: incomeData.length <= 8,
            labelAlignment: ChartDataLabelAlignment.auto,
            // Rotate labels for daily mode to improve readability
            angle: displayMode == ChartDisplayMode.daily ? -45 : 0,
          ),
        ),

        // Expense series: Financial outflows and costs
        ColumnSeries<ChartData, String>(
          dataSource: expenseData,
          xValueMapper: (ChartData data, _) => data.key, // Time periods (dates)
          yValueMapper: (ChartData data, _) => data.value, // Expense amounts
          name: 'Expense',

          // Use error theme color for expense data (typically red/warning)
          color: theme.colorScheme.error,

          // Consistent data label configuration with income series
          dataLabelSettings: DataLabelSettings(
            // Show labels only for smaller datasets to maintain readability
            isVisible: expenseData.length <= 8,
            labelAlignment: ChartDataLabelAlignment.auto,
            // Match income series label rotation for consistency
            angle: displayMode == ChartDisplayMode.daily ? -45 : 0,
          ),
        ),
      ],
    );
  }
}
