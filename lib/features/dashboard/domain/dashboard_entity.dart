class DashboardData {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<TransactionChartData> incomeChartData;
  final List<TransactionChartData> expenseChartData;
  final List<CategoryChartData> categoryDistribution;

  DashboardData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.incomeChartData,
    required this.expenseChartData,
    required this.categoryDistribution,
  });
}

class TransactionChartData {
  final DateTime date;
  final double amount;

  TransactionChartData(this.date, this.amount);
}

class CategoryChartData {
  final String category;
  final double amount;

  CategoryChartData(this.category, this.amount);
}