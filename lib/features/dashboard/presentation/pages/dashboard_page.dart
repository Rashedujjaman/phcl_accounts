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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  DateTimeRange? _dateRange;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// Determines appropriate text style based on amount size
  TextStyle _getAmountTextStyle(BuildContext context, double amount, {bool isMainCard = false}) {
    final theme = Theme.of(context);
    final absoluteAmount = amount.abs();
    
    if (isMainCard) {
      // For the main net revenue card
      if (absoluteAmount >= 100000000) { // 10 crore+
        return theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ) ?? const TextStyle();
      } else if (absoluteAmount >= 10000000) { // 1 crore+
        return theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ) ?? const TextStyle();
      } else if (absoluteAmount >= 1000000) { // 10 lakh+
        return theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ) ?? const TextStyle();
      } else {
        return theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ) ?? const TextStyle();
      }
    } else {
      // For income/expense cards
      if (absoluteAmount >= 100000000) { // 10 crore+
        return theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle();
      } else if (absoluteAmount >= 10000000) { // 1 crore+
        return theme.textTheme.titleSmall?.copyWith(
          fontSize: 14,
        ) ?? const TextStyle();
      } else if (absoluteAmount >= 1000000) { // 10 lakh+
        return theme.textTheme.titleMedium?.copyWith() ?? const TextStyle();
      } else {
        return theme.textTheme.titleLarge?.copyWith() ?? const TextStyle();
      }
    }
  }

  /// Creates an animated number widget with proper formatting
  Widget _buildAnimatedAmount(double amount, {
    required Color color,
    bool isMainCard = false,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue = Tween<double>(
          begin: 0,
          end: amount,
        ).animate(_animation).value;
        
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            NumberFormat.currency(symbol: '৳ ').format(animatedValue),
            style: _getAmountTextStyle(context, amount, isMainCard: isMainCard).copyWith(color: color),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      },
    );
  }


  void _loadInitialData() {
    final now = DateTime.now();
    // final firstDayOfYear = DateTime(now.year, 1, 1);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    _dateRange = DateTimeRange(start: firstDayOfMonth, end: now);
    _loadDashboardData();
  }

  void _loadDashboardData() {
    if (_dateRange == null) return;

    context.read<DashboardBloc>().add(
      LoadDashboardData(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      ),
    );
    
    // Reset and start animation
    _animationController.reset();
    _animationController.forward();
  }

  void _refreshDashboardData() {
    if (_dateRange == null) return;
    
    context.read<DashboardBloc>().add(
      RefreshDashboardData(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      ),
    );
    
    // Reset and start animation
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Dashboard'),
      // ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator( 
            onRefresh: () async => _refreshDashboardData(),
            child:  SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Show skeleton for date range selector only during initial loading
                  (state is DashboardInitial) 
                    ? const SkeletonDateRangeSelector()
                    : _buildDateRangeSelector(),
                  const SizedBox(height: 20),
                  _buildDashboardContent(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return DateRangeSelector(
      initialRange: _dateRange,
      onChanged: (range) {
        if (mounted) {
          setState(() => _dateRange = range);
          _loadDashboardData();
        }
      },
      presetLabels: const [
        'Today',
        'This Week',
        'This Month',
        'Last 3 Months',
        'Last 6 Months',
        'This Year',
      ],
    );
  }

  Widget _buildDashboardContent(DashboardState state) {
    if (state is DashboardInitial || state is DashboardLoading) {
      return Column(
        children: [
          const SkeletonDashboardSummary(),
          const SizedBox(height: 24),
          const SkeletonDisplayModeIndicator(),
          const SizedBox(height: 16),
          SkeletonChart(title: 'Revenue'),
          const Divider(),
          SkeletonChart(title: 'Income'),
          const Divider(),
          SkeletonChart(title: 'Expense'),
          const Divider(),
          SkeletonChart(title: 'Income vs Expense'),
          const SizedBox(height: 20),
          SkeletonPieChart(title: 'Expense Breakdown'),
          const SizedBox(height: 20),
          SkeletonPieChart(title: 'Income Breakdown'),
        ],
      );
    }

    if (state is DashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (state is DashboardLoaded || state is DashboardRefreshing) {
      final data = (state as DashboardLoaded).dashboardData;
      final isRefreshing = state is DashboardRefreshing;

      // Start animation when data is loaded for the first time
      if (!isRefreshing && _animationController.status == AnimationStatus.dismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animationController.forward();
          }
        });
      }

      return Column(
        children: [
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
          _buildSummaryCards(data),
          const SizedBox(height: 24),
          _buildDisplayModeIndicator(data),
          const SizedBox(height: 16),
          _buildRevenueTrendChart(data),
          const Divider(),
          // const SizedBox(height: 20),
          _buildIncomeTrendChart(data),
          const Divider(),
          _buildExpenseTrendChart(data),
          const Divider(),
          _buildIncomeVsExpenseChart(data),
          const SizedBox(height: 20),
          _buildExpenseCategoryDistributionChart(data),
          const SizedBox(height: 20),
          _buildIncomeCategoryDistributionChart(data),


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
                ? [theme.colorScheme.primary.withValues(alpha: 0.1), theme.colorScheme.tertiary.withValues(alpha: 0.05)]
                : [theme.colorScheme.error.withValues(alpha: 0.1), theme.colorScheme.errorContainer.withValues(alpha: 0.05)],
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
                      data.netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: data.netBalance >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
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
                          color: data.netBalance >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
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
                            color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                            color: theme.colorScheme.error.withValues(alpha: 0.15),
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                                        topRight: data.totalIncome == 0 ? const Radius.circular(4) : Radius.zero,
                                        bottomRight: data.totalIncome == 0 ? const Radius.circular(4) : Radius.zero,
                                        topLeft: data.totalIncome == 0 ? const Radius.circular(4) : Radius.zero,
                                        bottomLeft: data.totalIncome == 0 ? const Radius.circular(4) : Radius.zero,
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

  Widget _buildDisplayModeIndicator(DashboardData data) {
    final theme = Theme.of(context);
    final displayModeText = data.displayMode == ChartDisplayMode.daily ? 'Daily View' : 'Monthly View';
    final icon = data.displayMode == ChartDisplayMode.daily ? Icons.today : Icons.calendar_view_month;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
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

  Widget _buildExpenseCategoryDistributionChart(DashboardData data) {
    final theme = Theme.of(context);
    return PieChart(
      data: data.expenseCategoryDistribution,
      title: 'Expense Breakdown',
      borderColor: theme.colorScheme.error,
      // backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
    );
  }

  Widget _buildIncomeCategoryDistributionChart(DashboardData data) {
    final theme = Theme.of(context);
    return PieChart(
      data: data.incomeCategoryDistribution,
      title: 'Income Breakdown',
      borderColor: theme.colorScheme.tertiary,
    );
  }

  Widget _buildRevenueTrendChart(DashboardData data) {
    return CartesianLineChart(
      data: data.revenueTrendData,
      title: 'Revenue',
      displayMode: data.displayMode,
    );
  }

  Widget _buildIncomeTrendChart(DashboardData data) {
    return CartesianLineChart(
      data: data.incomeChartData,
      title: 'Income',
      displayMode: data.displayMode,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }

  Widget _buildExpenseTrendChart(DashboardData data) {
    return CartesianLineChart(
      data: data.expenseChartData,
      title: 'Expense',
      color: Theme.of(context).colorScheme.error,
      displayMode: data.displayMode,
    );
  }

  Widget _buildIncomeVsExpenseChart(DashboardData data) {
    return CartesianBarChart(
      incomeData: data.incomeChartData,
      expenseData: data.expenseChartData,
      title: 'Income vs Expense',
      displayMode: data.displayMode,
    );
  }
}