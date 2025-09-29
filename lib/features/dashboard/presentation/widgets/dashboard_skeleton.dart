import 'package:flutter/material.dart';
import 'package:phcl_accounts/core/widgets/skeleton_widgets.dart';

/// Skeleton for the main net revenue card
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
          const SkeletonCircle(size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonText(
                  width: 100,
                  height: 16,
                ),
                const SizedBox(height: 8),
                SkeletonText(
                  width: 180,
                  height: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for income/expense cards
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
              const SkeletonCircle(size: 36),
              SkeletonWidget(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonText(
            width: 80,
            height: 14,
          ),
          const SizedBox(height: 8),
          const SkeletonText(
            width: 120,
            height: 18,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for financial overview card
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
          Row(
            children: [
              const SkeletonCircle(size: 20),
              const SizedBox(width: 8),
              SkeletonText(
                width: 120,
                height: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonText(
            width: 140,
            height: 12,
          ),
          const SizedBox(height: 8),
          SkeletonWidget(
            width: double.infinity,
            height: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SkeletonWidget(
                width: 12,
                height: 12,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(width: 6),
              const SkeletonText(width: 50, height: 12),
              const SizedBox(width: 16),
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

/// Skeleton for chart widgets
class SkeletonChart extends StatelessWidget {
  final double height;
  final String? title;

  const SkeletonChart({
    super.key,
    this.height = 300,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            SkeletonText(
              width: 100,
              height: 18,
            ),
            const SizedBox(height: 16),
          ],
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

/// Skeleton for pie chart
class SkeletonPieChart extends StatelessWidget {
  final String? title;

  const SkeletonPieChart({
    super.key,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            SkeletonText(
              width: 120,
              height: 18,
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Row(
              children: [
                // Pie chart circle
                Expanded(
                  flex: 2,
                  child: Center(
                    child: SkeletonCircle(size: 120),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SkeletonWidget(
                              width: 12,
                              height: 12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: SkeletonText(height: 12),
                            ),
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

/// Skeleton for display mode indicator
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

/// Skeleton for date range selector
class SkeletonDateRangeSelector extends StatelessWidget {
  const SkeletonDateRangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom range selector
        SkeletonWidget(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        // Preset buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(6, (index) {
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

/// Combined skeleton for entire dashboard summary cards
class SkeletonDashboardSummary extends StatelessWidget {
  const SkeletonDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main revenue card
        const SkeletonNetRevenueCard(),
        const SizedBox(height: 16),
        
        // Income and expense cards row
        const Row(
          children: [
            Expanded(child: SkeletonIncomeExpenseCard()),
            SizedBox(width: 12),
            Expanded(child: SkeletonIncomeExpenseCard()),
          ],
        ),
        const SizedBox(height: 16),
        
        // Financial overview card
        const SkeletonFinancialOverviewCard(),
      ],
    );
  }
}
