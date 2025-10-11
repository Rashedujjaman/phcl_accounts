class DashboardData {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<ChartData> incomeChartData;
  final List<ChartData> expenseChartData;
  final List<ChartData> incomeCategoryDistribution;
  final List<ChartData> expenseCategoryDistribution;
  final List<ChartData> revenueTrendData;
  final List<ChartData> revenuePredictionData;
  final ChartDisplayMode displayMode;

  DashboardData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.incomeChartData,
    required this.expenseChartData,
    required this.incomeCategoryDistribution,
    required this.expenseCategoryDistribution,
    required this.revenueTrendData,
    required this.revenuePredictionData,
    required this.displayMode,
  });
}

enum ChartDisplayMode { daily, monthly }

class ChartData {
  final String key;
  final double value;

  ChartData(this.key, this.value);
}
