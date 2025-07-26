import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/cartesian_bar_chart.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/cartesian_line_chart.dart';
import 'package:phcl_accounts/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:phcl_accounts/core/widgets/date_range_selector.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/pie_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin {
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;


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
  }

  void _refreshDashboardData() {
    if (_dateRange == null) return;
    
    context.read<DashboardBloc>().add(
      RefreshDashboardData(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      ),
    );
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
                  _buildDateRangeSelector(),
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
    );
  }

  Widget _buildDashboardContent(DashboardState state) {
    if (state is DashboardInitial || state is DashboardLoading) {
      return const Center(child: CircularProgressIndicator());
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

      return Column(
        children: [
          if (isRefreshing)
            const LinearProgressIndicator(minHeight: 2),
          _buildSummaryCards(data),
          const SizedBox(height: 16),
          _buildDisplayModeIndicator(data),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.surfaceContainerHighest,theme.colorScheme.surfaceContainerLow, theme.colorScheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(0.785398), // 45 degrees in radians
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue: ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  NumberFormat.currency(symbol: '৳ ').format(data.netBalance),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: data.netBalance >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            Divider(
              thickness: 1,
              height: 24,
              color: theme.colorScheme.outline,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total In (+):',
                  style: TextStyle(fontSize: 16, color: theme.colorScheme.primary),
                ),
                Text(
                  NumberFormat.currency(symbol: '৳ ').format(data.totalIncome),
                  style: TextStyle(fontSize: 16, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Out (-):',
                  style: TextStyle(fontSize: 16, color: theme.colorScheme.error),
                ),
                Text(
                  NumberFormat.currency(symbol: '৳ ').format(data.totalExpense),
                  style: TextStyle(fontSize: 16, color: theme.colorScheme.error),
                ),
              ],
            ),
            Divider(
              thickness: 1,
              height: 24,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
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