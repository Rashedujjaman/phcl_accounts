import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CartesianBarChart extends StatelessWidget {
  final List<ChartData> incomeData;
  final List<ChartData> expenseData;
  final String title;
  final Color? color;

  final ChartDisplayMode? displayMode;

  const CartesianBarChart({super.key, required this.incomeData, required this.expenseData, required this.title, this.color, this.displayMode});

  @override 
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SfCartesianChart(
      title: ChartTitle(text: title),
      legend: const Legend(isVisible: true),
      primaryXAxis: CategoryAxis(
        labelRotation: displayMode == ChartDisplayMode.daily ? -45 : 0,
        labelIntersectAction: AxisLabelIntersectAction.multipleRows,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<ChartData, String>>[
        ColumnSeries<ChartData, String>(
          dataSource: incomeData,
          xValueMapper: (ChartData data, _) => data.key,
          yValueMapper: (ChartData data, _) => data.value,
          name: 'Income',
          color: theme.colorScheme.tertiary,
          dataLabelSettings: DataLabelSettings(
            isVisible: incomeData.length <= 8, // Show labels only for smaller datasets
            labelAlignment: ChartDataLabelAlignment.auto,
            angle: displayMode == ChartDisplayMode.daily ? -45 : 0,
          ),
        ),
        ColumnSeries<ChartData, String>(
          dataSource: expenseData,
          xValueMapper: (ChartData data, _) => data.key,
          yValueMapper: (ChartData data, _) => data.value,
          name: 'Expense',
          color: theme.colorScheme.error,
          dataLabelSettings: DataLabelSettings(
            isVisible: expenseData.length <= 8, // Show labels only for smaller datasets
            labelAlignment: ChartDataLabelAlignment.auto,
            angle: displayMode == ChartDisplayMode.daily ? -45 : 0,
          ),
        ),
      ],
    );
  }
}