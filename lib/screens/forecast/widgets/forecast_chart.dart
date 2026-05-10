import 'dart:math' as math;

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
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: lowerSpots,
          isCurved: true,
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      LineChartBarData(
        spots: predictedSpots,
        isCurved: true,
        color: colorScheme.primary,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ];

    final betweenBarsData = hasCi
        ? [
            BetweenBarsData(
              fromIndex: 0,
              toIndex: 1,
              color: colorScheme.primary.withValues(alpha: 0.14),
            ),
          ]
        : <BetweenBarsData>[];

    final dateFmt = DateFormat('d');
    final minY = hasCi
        ? points.map((p) => p.lowerCents! / 100).reduce((a, b) => a < b ? a : b)
        : points.map((p) => p.predictedCents / 100).reduce((a, b) => a < b ? a : b);
    final maxY = hasCi
        ? points.map((p) => p.upperCents! / 100).reduce((a, b) => a > b ? a : b)
        : points.map((p) => p.predictedCents / 100).reduce((a, b) => a > b ? a : b);
    final yPad = ((maxY - minY) * 0.1).abs().clamp(1.0, double.infinity);
    final yMin = minY - yPad;
    final yMax = maxY + yPad;
    final yInterval = _niceInterval(yMax - yMin, 4);
    final xInterval =
        (points.length / 7).ceilToDouble().clamp(1.0, double.infinity);

    final predictedBarIndex = lineBars.length - 1;
    final tooltipDateFmt = DateFormat('d MMM');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tooltipBg = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.inverseSurface;
    final tooltipFg = isDark
        ? colorScheme.onSurface
        : colorScheme.onInverseSurface;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          lineBarsData: lineBars,
          betweenBarsData: betweenBarsData,
          minY: yMin,
          maxY: yMax,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if ((value - yMin).abs() < yInterval * 0.01 ||
                      (yMax - value).abs() < yInterval * 0.01) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _formatAmount(value),
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateFmt.format(points[idx].date),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
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
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => tooltipBg,
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              tooltipMargin: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                final money = NumberFormat('#,##0.00');
                return touchedSpots.map((spot) {
                  if (spot.barIndex != predictedBarIndex) return null;
                  final idx = spot.x.toInt();
                  final point = (idx >= 0 && idx < points.length)
                      ? points[idx]
                      : null;
                  final headerStyle = TextStyle(
                    color: tooltipFg.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    height: 1.3,
                  );
                  final valueStyle = TextStyle(
                    color: tooltipFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  );
                  final ciLabelStyle = TextStyle(
                    color: tooltipFg.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    height: 1.4,
                  );
                  final ciValueStyle = TextStyle(
                    color: tooltipFg.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.4,
                  );

                  final children = <TextSpan>[];
                  if (point != null) {
                    children.add(TextSpan(
                      text: '${tooltipDateFmt.format(point.date)}\n',
                      style: headerStyle,
                    ));
                  }
                  children.add(TextSpan(
                    text: money.format(spot.y),
                    style: valueStyle,
                  ));
                  if (point?.lowerCents != null && point?.upperCents != null) {
                    final low = money.format(point!.lowerCents! / 100);
                    final high = money.format(point.upperCents! / 100);
                    children.add(TextSpan(
                      text: '\nHigh 80%  ',
                      style: ciLabelStyle,
                    ));
                    children.add(TextSpan(text: high, style: ciValueStyle));
                    children.add(TextSpan(
                      text: '\nLow 80%   ',
                      style: ciLabelStyle,
                    ));
                    children.add(TextSpan(text: low, style: ciValueStyle));
                  }
                  return LineTooltipItem(
                    '',
                    valueStyle,
                    children: children,
                    textAlign: TextAlign.left,
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((_) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, idx) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: colorScheme.surface,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  /// Picks a "round" axis interval close to `range / targetTicks` using a
  /// 1/2/5×10ⁿ progression, so labels never overlap regardless of scale.
  double _niceInterval(double range, int targetTicks) {
    if (range <= 0 || targetTicks <= 0) return 1;
    final raw = range / targetTicks;
    final mag = math.pow(10, raw.abs().log10().floor()).toDouble();
    final norm = raw / mag;
    final nice = norm < 1.5
        ? 1.0
        : norm < 3.5
            ? 2.0
            : norm < 7.5
                ? 5.0
                : 10.0;
    return nice * mag;
  }
}

extension on double {
  double log10() => math.log(this) / math.ln10;
}
