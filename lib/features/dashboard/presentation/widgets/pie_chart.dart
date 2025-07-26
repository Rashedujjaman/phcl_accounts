import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color? borderColor;
  final Color? backgroundColor;

  const PieChart({super.key, required this.data, required this.title, this.borderColor, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      title: ChartTitle(text: title),
      borderColor: borderColor ?? Theme.of(context).colorScheme.outline,
      borderWidth: 1,
      backgroundColor: backgroundColor,
      tooltipBehavior: TooltipBehavior(enable: true),
      legend: const Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        position: LegendPosition.bottom,
        // alignment: ChartAlignment.far,
      ),
      series: <PieSeries<ChartData, String>>[
        PieSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.key,
          yValueMapper: (ChartData data, _) => data.value,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            connectorLineSettings: ConnectorLineSettings(
              type: ConnectorType.curve,
              length: '15%',
            ),
          ),
          explode: true,
        ),
      ],
    );
  }
}