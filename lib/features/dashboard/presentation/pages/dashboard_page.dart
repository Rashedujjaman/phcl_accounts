import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
    final firstDayOfYear = DateTime(now.year, 1, 1);
    _dateRange = DateTimeRange(start: firstDayOfYear, end: now);
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
          const SizedBox(height: 20),
          _buildRevenueTrendChart(data),
          const SizedBox(height: 20),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  '৳${data.netBalance.toStringAsFixed(2)}',
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
                  '৳${data.totalIncome.toStringAsFixed(2)}',
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
                  '৳${data.totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
            const Divider(
              thickness: 1,
              height: 24,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCategoryDistributionChart(DashboardData data) {
    return PieChart(
      data: data.expenseCategoryDistribution,
      title: 'Expense Breakdown',
      borderColor: Colors.red,
    );
  }

  Widget _buildIncomeCategoryDistributionChart(DashboardData data) {
    return PieChart(
      data: data.incomeCategoryDistribution,
      title: 'Income Breakdown',
      borderColor: Colors.green,
    );
  }

  Widget _buildRevenueTrendChart(DashboardData data){
    return SfCartesianChart(
      title: ChartTitle(text: 'Revenue Trend'),
      legend: const Legend(isVisible: true),
      primaryXAxis: const CategoryAxis(
        labelRotation: -90,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<ChartData, String>>[
        LineSeries<ChartData, String>(
          dataSource: data.revenueTrendData,
          xValueMapper: (ChartData sales, _) => sales.key,
          yValueMapper: (ChartData sales, _) => sales.value,
          name: 'Revenue',
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildIncomeVsExpenseChart(DashboardData data) {
    return SfCartesianChart(
      title: const ChartTitle(text: 'Income vs Expense'),
      primaryXAxis: const CategoryAxis(),
      series: <CartesianSeries<ChartData, String>>[
        ColumnSeries<ChartData, String>(
          dataSource: data.incomeChartData,
          xValueMapper: (ChartData data, _) => data.key,
          yValueMapper: (ChartData data, _) => data.value,
          name: 'Income',
          color: Colors.green,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.auto,
            angle: -45,
          ),
        ),
        ColumnSeries<ChartData, String>(
          dataSource: data.expenseChartData,
          xValueMapper: (ChartData data, _) => data.key,
          yValueMapper: (ChartData data, _) => data.value,
          name: 'Expense',
          color: Colors.red,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.auto,
            angle: -45,
          ),
        ),
      ],
    );
  }
}