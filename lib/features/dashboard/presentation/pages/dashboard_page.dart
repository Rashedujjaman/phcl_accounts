import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:phcl_accounts/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/date_range_selector.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTimeRange? _dateRange;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  void _loadInitialData() {
    final now = DateTime.now();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator( 
            onRefresh: () async => _refreshDashboardData(),
            child:  SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DateRangeSelector(
                    initialRange: _dateRange,
                    onChanged: (range) {
                      if (mounted) {
                        setState(() => _dateRange = range);
                        _loadDashboardData();
                      }
                    },
                  ),
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
          const SizedBox(height: 20),
          _buildIncomeExpenseChart(data),
          const SizedBox(height: 20),
          _buildCategoryDistributionChart(data),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildSummaryCards(DashboardData data) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Balance: ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${data.netBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: data.netBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const Divider(
            thickness: 1,
            height: 24,
            color: Colors.grey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total In (+):',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
              Text(
                '₹${data.totalIncome.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Out (-):',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              Text(
                '₹${data.totalExpense.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
          const Divider(
            thickness: 1,
            height: 24,
            color: Colors.grey,
          ),
          // const Text('View Report'),
        ],
      ),
    ),
  );
}

  Widget _buildIncomeExpenseChart(DashboardData data) {
    if (data.incomeChartData.isEmpty && data.expenseChartData.isEmpty) {
      return const SizedBox();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Income vs Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                enableAxisAnimation: true,
                plotAreaBorderWidth: 0,
                margin: EdgeInsets.zero,
                primaryXAxis: DateTimeAxis(),
                series: <CartesianSeries>[
                  LineSeries<TransactionChartData, DateTime>(
                    dataSource: data.incomeChartData,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => data.amount,
                    name: 'Income',
                    color: Colors.green,
                  ),
                  LineSeries<TransactionChartData, DateTime>(
                    dataSource: data.expenseChartData,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => data.amount,
                    name: 'Expense',
                    color: Colors.red,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionChart(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<CategoryChartData, String>(
                    dataSource: data.categoryDistribution,
                    xValueMapper: (data, _) => data.category,
                    yValueMapper: (data, _) => data.amount,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    enableTooltip: true,
                  ),
                ],
                legend: Legend(isVisible: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}