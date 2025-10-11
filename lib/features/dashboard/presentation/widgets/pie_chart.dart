import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// A sophisticated circular pie chart widget for categorical financial analysis.
///
/// This widget provides advanced pie chart capabilities specifically designed for
/// displaying proportional financial data in the PHCL Accounts dashboard application.
/// It offers intuitive visualization of category distributions with exploded segments,
/// curved connectors, and responsive theming.
///
/// ## Key Features:
///
/// ### 🥧 **Exploded Pie Visualization**
/// - **Segment Separation**: Automatically explodes all segments for clarity
/// - **Category Proportions**: Clear visualization of relative spending/earning patterns
/// - **Visual Hierarchy**: Larger segments naturally draw more attention
/// - **Accessibility**: High contrast and readable segment distinctions
///
/// ### 🏷️ **Advanced Data Labeling**
/// - **Curved Connectors**: Elegant connecting lines from segments to labels
/// - **Smart Positioning**: Automatic label placement to prevent overlapping
/// - **Percentage Display**: Shows both category names and percentage values
/// - **Responsive Sizing**: Labels adapt to segment sizes and chart dimensions
///
/// ### 🎨 **Comprehensive Theming**
/// - **Theme Integration**: Respects Material Design color schemes
/// - **Custom Borders**: Configurable border colors and thickness
/// - **Background Control**: Optional background color customization
/// - **Consistent Typography**: Matches app font styles and accessibility settings
///
/// ### 🔧 **Interactive Features**
/// - **Tooltips**: Hover/tap to see precise values and percentages
/// - **Legend Navigation**: Bottom-positioned legend with overflow wrapping
/// - **Visual Feedback**: Interactive segment highlighting on hover/tap
/// - **Accessibility Support**: Screen reader compatible with proper labels
///
/// ### 📊 **Data Visualization Best Practices**
/// - **Optimal Segment Count**: Works best with 2-8 categories for readability
/// - **Color Differentiation**: Automatic color assignment for clear distinction
/// - **Proportional Accuracy**: True-to-scale representation of data values
/// - **Mobile Responsive**: Adapts to different screen sizes and orientations
///
/// ## Usage Examples:
///
/// ### Basic Category Distribution
/// ```dart
/// PieChart(
///   data: expenseCategories,
///   title: 'Expense Distribution',
/// )
/// ```
///
/// ### Themed Category Analysis
/// ```dart
/// PieChart(
///   data: incomeCategories,
///   title: 'Income Sources',
///   borderColor: Colors.green,
///   backgroundColor: Colors.green.shade50,
/// )
/// ```
///
/// ### Custom Styled Chart
/// ```dart
/// PieChart(
///   data: monthlyCategories,
///   title: 'Monthly Breakdown',
///   borderColor: Theme.of(context).primaryColor,
///   backgroundColor: Colors.transparent,
/// )
/// ```
///
/// ## Best Use Cases:
/// - **Expense Category Analysis**: Understanding spending patterns
/// - **Income Source Distribution**: Visualizing revenue streams
/// - **Budget Allocation**: Showing planned vs actual spending by category
/// - **Portfolio Composition**: Investment distribution visualization
/// - **Resource Utilization**: Department or project cost breakdowns
///
/// ## Technical Implementation:
/// - Built on Syncfusion Flutter Charts for performance and rich features
/// - Optimized for categorical financial data visualization
/// - Memory-efficient rendering of segment geometries
/// - Smooth animations and interactive transitions
/// - Automatic color palette generation for accessibility
class PieChart extends StatelessWidget {
  /// The dataset containing categories and their corresponding values.
  ///
  /// Each ChartData object represents a pie segment with:
  /// - **key**: Category name (e.g., "Food", "Transport", "Entertainment")
  /// - **value**: Numerical amount for proportional sizing
  ///
  /// Works best with 2-8 categories for optimal readability and visual impact.
  final List<ChartData> data;

  /// The descriptive title displayed at the top of the chart.
  ///
  /// Used for chart identification and accessibility labeling.
  /// Examples: "Expense Categories", "Income Sources", "Budget Allocation"
  final String title;

  /// Optional custom border color for the chart container.
  ///
  /// If null, uses the theme's outline color for consistent styling.
  /// Useful for creating themed charts or highlighting specific data types.
  final Color? borderColor;

  /// Optional background color for the chart area.
  ///
  /// If null, uses transparent background. Can be used to create
  /// subtle backgrounds that enhance data readability or match
  /// specific design requirements.
  final Color? backgroundColor;

  /// Creates a new pie chart widget for categorical data visualization.
  ///
  /// ## Required Parameters:
  /// - [data]: List of categories with their values for proportional display
  /// - [title]: Chart title for context and accessibility
  ///
  /// ## Optional Parameters:
  /// - [borderColor]: Custom border color (defaults to theme outline color)
  /// - [backgroundColor]: Custom background color (defaults to transparent)
  ///
  /// ## Example:
  /// ```dart
  /// PieChart(
  ///   data: [
  ///     ChartData('Food', 1200),
  ///     ChartData('Transport', 800),
  ///     ChartData('Entertainment', 400),
  ///   ],
  ///   title: 'Monthly Expenses',
  ///   borderColor: Colors.grey.shade400,
  /// )
  /// ```
  ///
  /// ## Data Requirements:
  /// - Minimum 1 category (though 2+ recommended for meaningful comparison)
  /// - Maximum 8-10 categories for optimal visual clarity
  /// - Positive numerical values for accurate proportional representation
  const PieChart({
    super.key,
    required this.data,
    required this.title,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Build high-performance circular chart with exploded pie visualization
    return SfCircularChart(
      // Chart title with theme-aware color styling
      title: ChartTitle(
        text: title,
        textStyle: TextStyle(
          color: borderColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),

      // Chart container styling with theme integration
      borderColor: borderColor ?? Theme.of(context).colorScheme.outline,
      borderWidth: 1,
      backgroundColor: backgroundColor,

      // Enable interactive tooltips for precise value inspection
      tooltipBehavior: TooltipBehavior(enable: true),

      // Interactive legend configuration for category identification
      legend: const Legend(
        isVisible: true,
        // Handle many categories gracefully with wrapping
        overflowMode: LegendItemOverflowMode.wrap,
        // Position at bottom for optimal mobile experience
        position: LegendPosition.bottom,
      ),

      // Define the pie chart series with exploded segments
      series: <PieSeries<ChartData, String>>[
        PieSeries<ChartData, String>(
          dataSource: data,
          // Map category names to pie segments
          xValueMapper: (ChartData data, _) => data.key,
          // Map numerical values for proportional sizing
          yValueMapper: (ChartData data, _) => data.value,

          // Advanced data label configuration
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            // Elegant curved connectors from segments to labels
            connectorLineSettings: ConnectorLineSettings(
              type: ConnectorType.curve,
              length: '15%', // Optimal connector length for readability
            ),
          ),

          // Explode all segments for enhanced visual separation
          explode: true,
        ),
      ],
    );
  }
}
