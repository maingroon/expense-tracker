import 'package:expense_tracker/models/forecast_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ForecastChart extends StatelessWidget {
  const ForecastChart({required this.forecast, super.key});

  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = forecast.points;
    if (points.isEmpty) return const SizedBox.shrink();

    final hasCi =
        points.first.lowerCents != null && points.first.upperCents != null;

    final predictedSpots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.predictedCents / 100);
    }).toList();

    final upperSpots = hasCi
        ? points.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.upperCents! / 100);
          }).toList()
        : <FlSpot>[];

    final lowerSpots = hasCi
        ? points.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.lowerCents! / 100);
          }).toList()
        : <FlSpot>[];

    final lineBars = <LineChartBarData>[
      if (hasCi) ...[
        LineChartBarData(
          spots: upperSpots,
          isCurved: true,
          color: colorScheme.primary.withAlpha(80),
          barWidth: 1,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: lowerSpots,
          isCurved: true,
          color: colorScheme.primary.withAlpha(80),
          barWidth: 1,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      LineChartBarData(
        spots: predictedSpots,
        isCurved: true,
        color: colorScheme.primary,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ];

    final betweenBarsData = hasCi
        ? [
            BetweenBarsData(
              fromIndex: 0,
              toIndex: 1,
              color: colorScheme.primary.withAlpha(30),
            ),
          ]
        : <BetweenBarsData>[];

    final dateFmt = DateFormat.Md();
    final minY = hasCi
        ? points.map((p) => p.lowerCents! / 100).reduce((a, b) => a < b ? a : b)
        : points.map((p) => p.predictedCents / 100).reduce((a, b) => a < b ? a : b);
    final maxY = hasCi
        ? points.map((p) => p.upperCents! / 100).reduce((a, b) => a > b ? a : b)
        : points.map((p) => p.predictedCents / 100).reduce((a, b) => a > b ? a : b);
    final yPad = ((maxY - minY) * 0.1).abs().clamp(1.0, double.infinity);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          lineBarsData: lineBars,
          betweenBarsData: betweenBarsData,
          minY: minY - yPad,
          maxY: maxY + yPad,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) => Text(
                  _formatAmount(value),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (points.length / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                  return Text(
                    dateFmt.format(points[idx].date),
                    style: Theme.of(context).textTheme.labelSmall,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colorScheme.outlineVariant,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }
}
