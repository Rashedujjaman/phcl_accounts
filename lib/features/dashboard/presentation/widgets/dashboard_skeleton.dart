import 'package:flutter/material.dart';
import 'package:phcl_accounts/core/widgets/skeleton_widgets.dart';

// ============================================================================
// DASHBOARD SKELETON WIDGETS
// ============================================================================
// This file contains skeleton loading widgets for the dashboard feature.
// Skeleton screens improve perceived performance by showing placeholder
// content while actual data is being fetched from Firebase or local storage.
//
// All widgets use the shimmer effect from the core skeleton_widgets.dart.
// ============================================================================

/// Skeleton loading widget for the main net revenue card
///
/// Displays a shimmer placeholder for the dashboard's primary revenue display
/// card, which typically shows the total net revenue amount and an icon.
///
/// **Layout:**
/// - Full width card with rounded corners
/// - Left side: Circular icon placeholder (52px)
/// - Right side: Two text lines for label and amount
///
/// **Usage:**
/// ```dart
/// SkeletonNetRevenueCard()
/// ```
class SkeletonNetRevenueCard extends StatelessWidget {
  const SkeletonNetRevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          // Icon placeholder - circular shape for revenue icon
          const SkeletonCircle(size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Label placeholder (e.g., "Net Revenue")
                SkeletonText(width: 100, height: 16),
                const SizedBox(height: 8),
                // Amount placeholder (e.g., "৳ 125,000")
                SkeletonText(width: 180, height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for income and expense summary cards
///
/// Displays a shimmer placeholder for compact income/expense cards that appear
/// side-by-side on the dashboard. Each card shows an icon, label, and amount.
///
/// **Layout:**
/// - Compact card with padding
/// - Top row: Icon (left) and menu indicator (right)
/// - Bottom: Label text and amount text
///
/// **Usage:**
/// ```dart
/// Row(
///   children: [
///     Expanded(child: SkeletonIncomeExpenseCard()), // Income
///     SizedBox(width: 12),
///     Expanded(child: SkeletonIncomeExpenseCard()), // Expense
///   ],
/// )
/// ```
class SkeletonIncomeExpenseCard extends StatelessWidget {
  const SkeletonIncomeExpenseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 120,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon placeholder (income/expense icon)
              const SkeletonCircle(size: 36),
              // Menu/options button placeholder
              SkeletonWidget(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Label placeholder (e.g., "Total Income")
          const SkeletonText(width: 80, height: 14),
          const SizedBox(height: 8),
          // Amount placeholder (e.g., "৳ 50,000")
          const SkeletonText(width: 120, height: 18),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for financial overview card with progress bar
///
/// Displays a shimmer placeholder for a detailed financial summary card
/// that typically includes a progress bar showing income vs expense ratio,
/// along with a legend and descriptive text.
///
/// **Layout:**
/// - Full width card
/// - Header: Icon + Title text
/// - Subtitle text
/// - Progress bar (horizontal)
/// - Legend: Two colored squares with labels
///
/// **Usage:**
/// ```dart
/// SkeletonFinancialOverviewCard()
/// ```
class SkeletonFinancialOverviewCard extends StatelessWidget {
  const SkeletonFinancialOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              // Icon placeholder
              const SkeletonCircle(size: 20),
              const SizedBox(width: 8),
              // Title placeholder (e.g., "Financial Overview")
              SkeletonText(width: 120, height: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Subtitle/description placeholder
          SkeletonText(width: 140, height: 12),
          const SizedBox(height: 8),
          // Progress bar placeholder
          SkeletonWidget(
            width: double.infinity,
            height: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          // Legend row with two items (e.g., Income: 60%, Expense: 40%)
          Row(
            children: [
              // First legend item
              SkeletonWidget(
                width: 12,
                height: 12,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(width: 6),
              const SkeletonText(width: 50, height: 12),
              const SizedBox(width: 16),
              // Second legend item
              SkeletonWidget(
                width: 12,
                height: 12,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(width: 6),
              const SkeletonText(width: 50, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for generic chart displays
///
/// A flexible skeleton for various chart types (line, bar, area charts).
/// Provides a rectangular placeholder with optional title section.
///
/// **Parameters:**
/// - [height]: Chart height in pixels (default: 300)
/// - [title]: Optional chart title to show placeholder for
///
/// **Usage:**
/// ```dart
/// SkeletonChart(
///   height: 250,
///   title: "Revenue Trends",
/// )
/// ```
class SkeletonChart extends StatelessWidget {
  /// Height of the chart skeleton in pixels
  final double height;

  /// Optional title to display above the chart
  final String? title;

  const SkeletonChart({super.key, this.height = 300, this.title});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show title placeholder if title is provided
          if (title != null) ...[
            SkeletonText(width: 100, height: 18),
            const SizedBox(height: 16),
          ],
          // Chart area placeholder
          Expanded(
            child: SkeletonWidget(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for pie/donut chart with legend
///
/// Displays a shimmer placeholder specifically designed for pie charts,
/// including a circular chart area on the left and a legend list on the right.
/// Commonly used for category-wise expense/income distribution visualizations.
///
/// **Layout:**
/// - Left side (60%): Circular chart placeholder (120px diameter)
/// - Right side (40%): Legend with 4 items (color box + label)
///
/// **Parameters:**
/// - [title]: Optional chart title to show placeholder for
///
/// **Usage:**
/// ```dart
/// SkeletonPieChart(
///   title: "Expense by Category",
/// )
/// ```
class SkeletonPieChart extends StatelessWidget {
  /// Optional title to display above the chart
  final String? title;

  const SkeletonPieChart({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show title placeholder if title is provided
          if (title != null) ...[
            SkeletonText(width: 120, height: 18),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Row(
              children: [
                // Pie chart circle placeholder (left side)
                Expanded(
                  flex: 2,
                  child: Center(child: SkeletonCircle(size: 120)),
                ),
                const SizedBox(width: 16),
                // Legend section (right side)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(4, (index) {
                      // Generate 4 legend items (category placeholders)
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            // Color indicator box
                            SkeletonWidget(
                              width: 12,
                              height: 12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            const SizedBox(width: 8),
                            // Category label placeholder
                            const Expanded(child: SkeletonText(height: 12)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for display mode indicator button
///
/// Displays a shimmer placeholder for the display mode toggle button,
/// typically used to switch between different view modes (e.g., grid/list,
/// chart/table views) on the dashboard.
///
/// **Layout:**
/// - Pill-shaped button (120x32px)
/// - Rounded corners (20px radius)
///
/// **Usage:**
/// ```dart
/// SkeletonDisplayModeIndicator()
/// ```
class SkeletonDisplayModeIndicator extends StatelessWidget {
  const SkeletonDisplayModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonWidget(
      width: 120,
      height: 32,
      borderRadius: BorderRadius.circular(20),
    );
  }
}

/// Skeleton loading widget for date range selector with preset buttons
///
/// Displays a shimmer placeholder for the date range selection UI,
/// including a custom range selector input field and horizontal scrolling
/// preset buttons (Today, This Week, This Month, etc.).
///
/// **Layout:**
/// - Top: Full-width date range input field (48px height)
/// - Bottom: Horizontal scrollable row of 6 preset buttons (80x32px each)
///
/// **Usage:**
/// ```dart
/// SkeletonDateRangeSelector()
/// ```
class SkeletonDateRangeSelector extends StatelessWidget {
  const SkeletonDateRangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom date range input field placeholder
        SkeletonWidget(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        // Preset filter buttons (Today, This Week, This Month, etc.)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(6, (index) {
              // Generate 6 preset button placeholders
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SkeletonWidget(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Combined skeleton loading widget for complete dashboard summary section
///
/// A comprehensive skeleton that combines all dashboard summary card placeholders
/// in the proper layout structure. This is the main skeleton widget used when
/// the dashboard is loading financial data from Firebase or local storage.
///
/// **Layout Structure:**
/// 1. Net Revenue Card (full width)
/// 2. Income & Expense Cards (two cards side-by-side)
/// 3. Financial Overview Card (full width with progress bar)
///
/// **Usage:**
/// ```dart
/// // In dashboard page when loading
/// BlocBuilder<DashboardBloc, DashboardState>(
///   builder: (context, state) {
///     if (state is DashboardLoading) {
///       return SkeletonDashboardSummary();
///     }
///     return DashboardSummaryContent(data: state.data);
///   },
/// )
/// ```
class SkeletonDashboardSummary extends StatelessWidget {
  const SkeletonDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Main net revenue card (shows total revenue with icon)
        const SkeletonNetRevenueCard(),
        const SizedBox(height: 16),

        // 2. Income and expense summary cards in a row
        const Row(
          children: [
            Expanded(child: SkeletonIncomeExpenseCard()), // Income card
            SizedBox(width: 12),
            Expanded(child: SkeletonIncomeExpenseCard()), // Expense card
          ],
        ),
        const SizedBox(height: 16),

        // 3. Financial overview card with progress indicator
        const SkeletonFinancialOverviewCard(),
      ],
    );
  }
}
