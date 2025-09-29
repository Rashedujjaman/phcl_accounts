import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CartesianLineChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color? color;

  final ChartDisplayMode? displayMode;

  const CartesianLineChart({super.key, required this.data, required this.title, this.color, this.displayMode});

  @override
  Widget build(BuildContext context) {
      // final displayModeText = displayMode == ChartDisplayMode.daily ? 'Daily' : 'Monthly';
      return SfCartesianChart(
        title: ChartTitle(text: '$title Trend', textStyle: TextStyle(color: color ?? Theme.of(context).colorScheme.primary)),
        legend: const Legend(isVisible: true),
        primaryXAxis: CategoryAxis(
          labelRotation: displayMode == ChartDisplayMode.daily ? -45 : -90,
          labelIntersectAction: AxisLabelIntersectAction.multipleRows,
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData sales, _) => sales.key,
            yValueMapper: (ChartData sales, _) => sales.value,
            name: title,
            color: color,
            dataLabelSettings: DataLabelSettings(
              isVisible: data.length <= 10,
              labelAlignment: ChartDataLabelAlignment.auto,
            ),
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      );
  }
}