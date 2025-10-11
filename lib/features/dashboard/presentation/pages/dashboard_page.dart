import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/cartesian_bar_chart.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/cartesian_line_chart.dart';
import 'package:phcl_accounts/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:phcl_accounts/core/widgets/date_range_selector.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/pie_chart.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:phcl_accounts/core/widgets/skeleton_widgets.dart';

/// Main dashboard page displaying comprehensive financial analytics and metrics.
///
/// Provides an interactive financial overview with the following key features:
/// - Real-time financial summary (net revenue, total income, total expense)
/// - Interactive date range filtering with preset options
/// - Animated charts for trend analysis (daily/monthly views)
/// - Category-wise distribution charts (pie charts)
/// - Financial health indicators and ratios
/// - Pull-to-refresh functionality
/// - Skeleton loading states for smooth UX
/// - Automatic keep-alive for performance optimization
///
/// The dashboard uses BLoC pattern for state management and provides smooth
/// animations for enhanced user experience. All monetary values are displayed
/// in Bangladeshi Taka (৳) with proper formatting and responsive text sizing.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

/// State class for DashboardPage with animation and lifecycle management.
///
/// Implements AutomaticKeepAliveClientMixin to preserve state when navigating
/// between tabs and TickerProviderStateMixin for smooth animations.
class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  /// Current selected date range for filtering dashboard data
  DateTimeRange? _dateRange;

  /// Animation controller for smooth number transitions and card animations
  late AnimationController _animationController;

  /// Curved animation for natural easing effects
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation system for smooth value transitions
    _animationController = AnimationController(
      duration: const Duration(
        milliseconds: 1200,
      ), // 1.2 seconds for smooth animation
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Natural easing for professional feel
    );

    // Load initial dashboard data with default date range
    _loadInitialData();
  }

  @override
  void dispose() {
    // Clean up animation resources to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  /// Keep the dashboard alive when switching tabs for better performance
  @override
  bool get wantKeepAlive => true;

  /// Determines responsive text style based on monetary amount magnitude.
  ///
  /// Implements adaptive typography that scales appropriately with large financial values
  /// to prevent UI overflow and maintain readability across different amount ranges.
  ///
  /// Parameters:
  /// - [context]: Build context for theme access
  /// - [amount]: Monetary value to determine styling for
  /// - [isMainCard]: Whether this is for the main net revenue card (larger emphasis)
  ///
  /// Returns:
  /// - [TextStyle]: Appropriately sized text style for the given amount
  ///
  /// Amount Ranges (Indian currency system):
  /// - 10 crore+ (100,000,000): Smallest text to fit large numbers
  /// - 1-10 crore (10,000,000-99,999,999): Small to medium text
  /// - 10 lakh-1 crore (1,000,000-9,999,999): Medium text
  /// - Below 10 lakh (< 1,000,000): Large text for readability
  TextStyle _getAmountTextStyle(
    BuildContext context,
    double amount, {
    bool isMainCard = false,
  }) {
    final theme = Theme.of(context);
    final absoluteAmount = amount.abs();

    if (isMainCard) {
      // Responsive typography for main net revenue card
      if (absoluteAmount >= 100000000) {
        // 10 crore+ - use smaller text to fit
        return theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ) ??
            const TextStyle();
      } else if (absoluteAmount >= 10000000) {
        // 1 crore+ - medium size
        return theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ) ??
            const TextStyle();
      } else if (absoluteAmount >= 1000000) {
        // 10 lakh+ - larger size
        return theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle();
      } else {
        // Below 10 lakh - largest size for impact
        return theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle();
      }
    } else {
      // Responsive typography for secondary cards (income/expense)
      if (absoluteAmount >= 100000000) {
        // 10 crore+ - compact text
        return theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle();
      } else if (absoluteAmount >= 10000000) {
        // 1 crore+ - small text
        return theme.textTheme.titleSmall?.copyWith(fontSize: 14) ??
            const TextStyle();
      } else if (absoluteAmount >= 1000000) {
        // 10 lakh+ - medium text
        return theme.textTheme.titleMedium?.copyWith() ?? const TextStyle();
      } else {
        // Below 10 lakh - larger text
        return theme.textTheme.titleLarge?.copyWith() ?? const TextStyle();
      }
    }
  }

  /// Creates an animated monetary amount widget with smooth number transitions.
  ///
  /// Provides engaging visual feedback through smooth counting animations from 0 to
  /// the target value, enhancing user experience with professional polish.
  ///
  /// Parameters:
  /// - [amount]: Target monetary value to animate to
  /// - [color]: Text color for the amount display
  /// - [isMainCard]: Whether this is for the main card (affects text sizing)
  ///
  /// Returns:
  /// - [Widget]: Animated text widget with currency formatting (Bangladeshi Taka)
  ///
  /// Features:
  /// - Smooth counting animation from 0 to target value
  /// - Automatic text scaling to prevent overflow
  /// - Proper currency formatting with ৳ symbol
  /// - Responsive typography based on amount magnitude
  Widget _buildAnimatedAmount(
    double amount, {
    required Color color,
    bool isMainCard = false,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate interpolated value for smooth counting effect
        final animatedValue = Tween<double>(
          begin: 0,
          end: amount,
        ).animate(_animation).value;

        return FittedBox(
          fit: BoxFit.scaleDown, // Scale down if needed to prevent overflow
          alignment: Alignment.centerLeft,
          child: Text(
            NumberFormat.currency(symbol: '৳ ').format(animatedValue),
            style: _getAmountTextStyle(
              context,
              amount,
              isMainCard: isMainCard,
            ).copyWith(color: color),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      },
    );
  }

  /// Initializes dashboard with default date range (current month).
  ///
  /// Sets up the initial view to show current month's financial data,
  /// providing immediate relevant insights without requiring user interaction.
  /// This default range balances recency with meaningful data volume.
  void _loadInitialData() {
    final now = DateTime.now();
    // Set default range to current month for relevant recent data
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    _dateRange = DateTimeRange(start: firstDayOfMonth, end: now);
    _loadDashboardData();
  }

  /// Loads dashboard data for the currently selected date range.
  ///
  /// Triggers BLoC event to fetch financial data and starts the animation
  /// sequence for smooth visual transitions when data updates.
  ///
  /// Process:
  /// 1. Validates date range is available
  /// 2. Dispatches LoadDashboardData event to BLoC
  /// 3. Resets and starts counting animations for engaging UX
  void _loadDashboardData() {
    if (_dateRange == null) return;

    // Request fresh data from BLoC layer
    context.read<DashboardBloc>().add(
      LoadDashboardData(startDate: _dateRange!.start, endDate: _dateRange!.end),
    );

    // Reset and start animation for smooth value transitions
    _animationController.reset();
    _animationController.forward();
  }

  /// Refreshes dashboard data with pull-to-refresh functionality.
  ///
  /// Provides manual refresh capability for users to get the latest
  /// financial data without navigating away from the dashboard.
  ///
  /// Process:
  /// 1. Validates date range availability
  /// 2. Dispatches RefreshDashboardData event for updated data
  /// 3. Triggers animation reset for consistent visual feedback
  void _refreshDashboardData() {
    if (_dateRange == null) return;

    // Request data refresh from BLoC layer
    context.read<DashboardBloc>().add(
      RefreshDashboardData(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      ),
    );

    // Reset and start animation for fresh data display
    _animationController.reset();
    _animationController.forward();
  }

  /// Builds the main dashboard UI with responsive layout and state management.
  ///
  /// Creates a comprehensive financial dashboard with the following components:
  /// - Pull-to-refresh functionality for data updates
  /// - Responsive date range selector with skeleton loading
  /// - Dynamic content based on BLoC state management
  /// - Smooth scrolling with proper padding and spacing
  ///
  /// The build method maintains widget tree across rebuilds using
  /// AutomaticKeepAliveClientMixin for optimal performance.
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            // Enable pull-to-refresh for manual data updates
            onRefresh: () async => _refreshDashboardData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16), // Consistent spacing
              child: Column(
                children: [
                  // Date range selector with skeleton loading for initial state
                  (state is DashboardInitial)
                      ? const SkeletonDateRangeSelector() // Show skeleton during initial load
                      : _buildDateRangeSelector(), // Show actual selector when ready
                  const SizedBox(height: 20),

                  // Main dashboard content managed by state
                  _buildDashboardContent(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the interactive date range selector with preset options.
  ///
  /// Provides users with flexible filtering options through:
  /// - Custom date range selection via date picker
  /// - Convenient preset options for common time periods
  /// - Immediate data refresh when selection changes
  ///
  /// Returns:
  /// - [Widget]: Configured DateRangeSelector with preset options and callbacks
  Widget _buildDateRangeSelector() {
    return DateRangeSelector(
      initialRange: _dateRange, // Current selected range
      onChanged: (range) {
        // Update date range and refresh data when user makes selection
        if (mounted) {
          // Ensure widget is still in tree before setState
          setState(() => _dateRange = range);
          _loadDashboardData(); // Fetch new data for selected range
        }
      },
      // Preset options for common financial reporting periods
      presetLabels: const [
        'Today', // Current day transactions
        'This Week', // Current week overview
        'This Month', // Current month (default)
        'Last 3 Months', // Quarterly view
        'Last 6 Months', // Semi-annual analysis
        'This Year', // Annual overview
      ],
    );
  }

  /// Builds dashboard content based on current BLoC state with proper loading states.
  ///
  /// Handles different dashboard states to provide appropriate UI feedback:
  /// - Loading states: Shows skeleton placeholders for smooth UX
  /// - Error states: Displays error message with retry functionality
  /// - Loaded states: Shows complete dashboard with all financial data
  /// - Refreshing states: Maintains UI while showing refresh indicator
  ///
  /// Parameters:
  /// - [state]: Current DashboardState from BLoC
  ///
  /// Returns:
  /// - [Widget]: Appropriate UI based on current state
  Widget _buildDashboardContent(DashboardState state) {
    // Show skeleton loading UI during initial load or loading states
    if (state is DashboardInitial || state is DashboardLoading) {
      return Column(
        children: [
          // Skeleton placeholders maintain layout structure during loading
          const SkeletonDashboardSummary(), // Summary cards skeleton
          const SizedBox(height: 24),
          const SkeletonDisplayModeIndicator(), // Display mode indicator skeleton
          const SizedBox(height: 16),

          // Chart skeleton placeholders with titles
          SkeletonChart(title: 'Revenue'),
          const Divider(),
          SkeletonChart(title: 'Income'),
          const Divider(),
          SkeletonChart(title: 'Expense'),
          const Divider(),
          SkeletonChart(title: 'Income vs Expense'),
          const SizedBox(height: 20),

          // Pie chart skeleton placeholders
          SkeletonPieChart(title: 'Expense Breakdown'),
          const SizedBox(height: 20),
          SkeletonPieChart(title: 'Income Breakdown'),
        ],
      );
    }

    // Show error state with retry functionality
    if (state is DashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message), // Display error message
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData, // Allow user to retry
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loaded dashboard content with full financial analytics
    if (state is DashboardLoaded || state is DashboardRefreshing) {
      final data = (state as DashboardLoaded).dashboardData;
      final isRefreshing = state is DashboardRefreshing;

      // Trigger animation for first-time data load (not during refresh)
      if (!isRefreshing &&
          _animationController.status == AnimationStatus.dismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animationController.forward(); // Start counting animations
          }
        });
      }

      return Column(
        children: [
          // Show subtle refresh indicator during refresh operations
          if (isRefreshing)
            Container(
              height: 2,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: SkeletonWidget(
                width: double.infinity,
                height: 2,
                borderRadius: BorderRadius.circular(1),
              ),
            ),

          // Core dashboard components with financial data
          _buildSummaryCards(data), // Net revenue, income, expense cards
          const SizedBox(height: 24),
          _buildDisplayModeIndicator(data), // Daily/Monthly view indicator
          const SizedBox(height: 16),

          // Financial trend charts with dividers for visual separation
          if (data.revenueTrendData.isNotEmpty) ...[
            _buildRevenueTrendChart(data), // Net revenue over time
            const Divider(),
          ],
          if (data.incomeChartData.isNotEmpty) ...[
            _buildIncomeTrendChart(data), // Income trend analysis
            const Divider(),
          ],
          if (data.expenseChartData.isNotEmpty) ...[
            _buildExpenseTrendChart(data), // Expense trend analysis
            const Divider(),
          ],
          if (data.incomeChartData.isNotEmpty &&
              data.expenseChartData.isNotEmpty) ...[
            _buildIncomeVsExpenseChart(data), // Comparative bar chart
            const SizedBox(height: 20),
          ],

          // Category distribution analysis
          if (data.expenseCategoryDistribution.isNotEmpty) ...[
            _buildExpenseCategoryDistributionChart(data), // Expense breakdown
            const SizedBox(height: 20),
          ],

          if (data.incomeCategoryDistribution.isNotEmpty) ...[
            _buildIncomeCategoryDistributionChart(data), // Income sources
            const SizedBox(height: 20),
          ],

          // Revenue prediction chart
          if (data.revenuePredictionData.isNotEmpty)
            _buildRevenuePredictionChart(data), // Revenue predictions
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildSummaryCards(DashboardData data) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Main Revenue Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: data.netBalance >= 0
                  ? [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.tertiary.withValues(alpha: 0.05),
                    ]
                  : [
                      theme.colorScheme.error.withValues(alpha: 0.1),
                      theme.colorScheme.errorContainer.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: data.netBalance >= 0
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.error.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: data.netBalance >= 0
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      data.netBalance >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: data.netBalance >= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Revenue',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildAnimatedAmount(
                          data.netBalance,
                          color: data.netBalance >= 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                          isMainCard: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Income and Expense Cards Row
        Row(
          children: [
            // Income Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: theme.colorScheme.tertiary,
                            size: 20,
                          ),
                        ),
                        Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total Income',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAnimatedAmount(
                      data.totalIncome,
                      color: theme.colorScheme.tertiary,
                      isMainCard: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Expense Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_downward,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                        ),
                        Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total Expense',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAnimatedAmount(
                      data.totalExpense,
                      color: theme.colorScheme.error,
                      isMainCard: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Financial Health Indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Financial Overview',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Income vs Expense Ratio Bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Income vs Expense Ratio',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              data.totalIncome > 0
                                  ? '${((data.totalIncome / (data.totalIncome + data.totalExpense)) * 100).toStringAsFixed(1)}%'
                                  : '0%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Row(
                            children: [
                              if (data.totalIncome > 0)
                                Expanded(
                                  flex: data.totalIncome.toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                ),
                              if (data.totalExpense > 0)
                                Expanded(
                                  flex: data.totalExpense.toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topRight: data.totalIncome == 0
                                            ? const Radius.circular(4)
                                            : Radius.zero,
                                        bottomRight: data.totalIncome == 0
                                            ? const Radius.circular(4)
                                            : Radius.zero,
                                        topLeft: data.totalIncome == 0
                                            ? const Radius.circular(4)
                                            : Radius.zero,
                                        bottomLeft: data.totalIncome == 0
                                            ? const Radius.circular(4)
                                            : Radius.zero,
                                      ),
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Income',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Expense',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the display mode indicator showing current chart view mode.
  ///
  /// Provides visual feedback about the current chart aggregation level:
  /// - Daily View: Shows day-by-day transaction patterns
  /// - Monthly View: Shows month-by-month aggregated data
  ///
  /// The indicator helps users understand the granularity of the displayed data
  /// and provides context for interpreting the financial charts.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing the current display mode
  ///
  /// Returns:
  /// - [Widget]: Styled indicator chip with appropriate icon and text
  Widget _buildDisplayModeIndicator(DashboardData data) {
    final theme = Theme.of(context);

    // Determine display text and icon based on current mode
    final displayModeText = data.displayMode == ChartDisplayMode.daily
        ? 'Daily View'
        : 'Monthly View';
    final icon = data.displayMode == ChartDisplayMode.daily
        ? Icons.today
        : Icons.calendar_view_month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20), // Pill-shaped design
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Compact layout
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            displayModeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds expense category distribution pie chart for spending analysis.
  ///
  /// Displays proportional breakdown of expenses across different categories,
  /// helping users identify major spending areas and budget optimization opportunities.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing expense category distribution
  ///
  /// Returns:
  /// - [Widget]: Pie chart with expense categories and amounts
  Widget _buildExpenseCategoryDistributionChart(DashboardData data) {
    final theme = Theme.of(context);
    return PieChart(
      data: data.expenseCategoryDistribution,
      title: 'Expense Breakdown',
      borderColor: theme.colorScheme.error, // Red theme for expenses
    );
  }

  /// Builds income category distribution pie chart for revenue source analysis.
  ///
  /// Displays proportional breakdown of income across different sources,
  /// helping users understand revenue diversification and source reliability.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing income category distribution
  ///
  /// Returns:
  /// - [Widget]: Pie chart with income sources and amounts
  Widget _buildIncomeCategoryDistributionChart(DashboardData data) {
    final theme = Theme.of(context);
    return PieChart(
      data: data.incomeCategoryDistribution,
      title: 'Income Breakdown',
      borderColor: theme.colorScheme.tertiary, // Green theme for income
    );
  }

  /// Builds net revenue trend line chart showing financial health over time.
  ///
  /// Displays the overall financial performance by showing net revenue
  /// (income minus expenses) trends, helping identify growth patterns.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing revenue trend information
  ///
  /// Returns:
  /// - [Widget]: Line chart showing revenue trends over selected period
  Widget _buildRevenueTrendChart(DashboardData data) {
    return CartesianLineChart(
      data: data.revenueTrendData,
      title: 'Revenue',
      displayMode: data.displayMode, // Daily or monthly aggregation
    );
  }

  /// Builds income trend line chart for revenue pattern analysis.
  ///
  /// Displays income trends over time to help identify seasonal patterns,
  /// growth trends, and revenue consistency for business planning.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing income chart data
  ///
  /// Returns:
  /// - [Widget]: Line chart with income trends in tertiary color theme
  Widget _buildIncomeTrendChart(DashboardData data) {
    return CartesianLineChart(
      data: data.incomeChartData,
      title: 'Income',
      displayMode: data.displayMode,
      color: Theme.of(context).colorScheme.tertiary, // Green for income
    );
  }

  /// Builds expense trend line chart for spending pattern analysis.
  ///
  /// Displays expense trends over time to help identify spending patterns,
  /// budget adherence, and cost optimization opportunities.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing expense chart data
  ///
  /// Returns:
  /// - [Widget]: Line chart with expense trends in error color theme
  Widget _buildExpenseTrendChart(DashboardData data) {
    return CartesianLineChart(
      data: data.expenseChartData,
      title: 'Expense',
      color: Theme.of(context).colorScheme.error, // Red for expenses
      displayMode: data.displayMode,
    );
  }

  /// Builds comparative bar chart showing income vs expense side by side.
  ///
  /// Provides direct visual comparison between income and expenses over time,
  /// making it easy to identify periods of profit/loss and financial balance.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing both income and expense chart data
  ///
  /// Returns:
  /// - [Widget]: Bar chart with side-by-side income and expense comparison
  Widget _buildIncomeVsExpenseChart(DashboardData data) {
    return CartesianBarChart(
      incomeData: data.incomeChartData, // Green bars for income
      expenseData: data.expenseChartData, // Red bars for expenses
      title: 'Income vs Expense',
      displayMode: data.displayMode,
    );
  }

  /// Builds revenue prediction line chart using ML-driven forecasts.
  ///
  /// Displays predicted revenue trends based on historical data and ML models,
  /// helping users visualize future financial performance.
  ///
  /// Parameters:
  /// - [data]: Dashboard data containing revenue prediction information
  ///
  /// Returns:
  /// - [Widget]: Line chart showing predicted revenue trends
  Widget _buildRevenuePredictionChart(DashboardData data) {
    return CartesianLineChart(
      data: data.revenueTrendData,
      title: 'Revenue Prediction',
      displayMode: data.displayMode,
      predictionData: data.revenuePredictionData,
    );
  }
}
