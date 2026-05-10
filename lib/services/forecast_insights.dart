import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/forecast_insight.dart';
import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/forecast_risk.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Ratio thresholds for "over budget" / "spending less" branches.
const double kInsightOverRatio = 1.20;
const double kInsightUnderRatio = 0.80;

/// Show overdraft warnings only when the probability is at least this large.
/// Below the threshold the noise dominates and we suppress the line.
const double kInsightOverdraftThreshold = 0.10;

/// Maximum number of insights surfaced to the UI at once.
const int kMaxInsights = 3;

/// Builds a ranked list of [ForecastInsight]s combining the balance forecast,
/// per-category forecasts, and 30-day historical baselines pulled through
/// [aggregation].
///
/// Ranking: danger > warning > positive > neutral. Ties are broken by larger
/// magnitude (e.g. the most-over category wins).
Future<List<ForecastInsight>> buildInsights({
  required Forecast balanceForecast,
  required List<({Category category, Forecast forecast})> categoryForecasts,
  required AggregationService aggregation,
  required DateTime asOf,
}) async {
  final insights = <ForecastInsight>[];

  // ── Overdraft warning (uses point-3 helper). ──
  final risk = overdraftRisk(balanceForecast);
  if (risk.endOfHorizon >= kInsightOverdraftThreshold) {
    final pct = (risk.endOfHorizon * 100).round();
    insights.add(ForecastInsight(
      severity: pct >= 25 ? InsightSeverity.danger : InsightSeverity.warning,
      icon: Icons.warning_amber_rounded,
      title: 'Risk of overdraft within ${balanceForecast.horizonDays} days: $pct%',
      detail: 'Projected balance may dip below zero before '
          '${DateFormat.MMMd().format(balanceForecast.points.last.date)}.',
    ));
  }

  // ── Balance trajectory. ──
  if (balanceForecast.points.isNotEmpty) {
    final last = balanceForecast.points.last;
    final first = balanceForecast.points.first;
    final delta = last.predictedCents - first.predictedCents;
    if (delta.abs() >= 100) {
      insights.add(ForecastInsight(
        severity: delta >= 0 ? InsightSeverity.positive : InsightSeverity.neutral,
        icon: delta >= 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        title: delta >= 0
            ? 'On track to save ${_fmtCents(delta.abs())} this period'
            : 'Balance projected to drop by ${_fmtCents(delta.abs())} this period',
        detail: 'Projected change in balance over the next '
            '${balanceForecast.horizonDays} days.',
      ));
    }
  }

  // ── Per-category baseline comparison. ──
  if (categoryForecasts.isNotEmpty) {
    final from = DateTime(asOf.year, asOf.month, asOf.day)
        .subtract(const Duration(days: 30));
    final to = DateTime(asOf.year, asOf.month, asOf.day)
        .subtract(const Duration(days: 1));
    final baselines = await categoryBaselines(
      aggregation: aggregation,
      categoryIds: categoryForecasts.map((c) => c.category.id).toList(),
      from: from,
      to: to,
    );

    for (final item in categoryForecasts) {
      final projected = _sumPredicted(item.forecast);
      final baseline30d = baselines[item.category.id] ?? 0;
      if (baseline30d <= 0) continue;
      final scaledBaseline = baseline30d * item.forecast.horizonDays / 30;
      if (scaledBaseline <= 0) continue;
      final ratio = projected / scaledBaseline;
      final pctDelta = ((ratio - 1) * 100).round();
      if (ratio >= kInsightOverRatio) {
        insights.add(ForecastInsight(
          severity: ratio >= 1.50
              ? InsightSeverity.danger
              : InsightSeverity.warning,
          icon: Icons.trending_up_rounded,
          title: '${item.category.name} projected +$pctDelta% vs recent average',
          detail: 'Consider reviewing recent ${item.category.name.toLowerCase()} spending.',
        ));
      } else if (ratio <= kInsightUnderRatio) {
        insights.add(ForecastInsight(
          severity: InsightSeverity.positive,
          icon: Icons.trending_down_rounded,
          title: '${item.category.name} projected ${pctDelta.abs()}% below recent average',
          detail: 'You are spending less on ${item.category.name.toLowerCase()} than usual.',
        ));
      }
    }
  }

  insights.sort((a, b) {
    return b.severity.index.compareTo(a.severity.index);
  });

  return insights.take(kMaxInsights).toList();
}

/// Returns the 30-day expense total per category (positive cents) for use as a
/// baseline. Categories with no expense activity are absent from the map.
Future<Map<String, int>> categoryBaselines({
  required AggregationService aggregation,
  required List<String> categoryIds,
  required DateTime from,
  required DateTime to,
}) async {
  if (categoryIds.isEmpty) return const {};
  final rows = await aggregation.getDailyByCategory(
    from: from,
    to: to,
    categoryIds: categoryIds,
  );
  final totals = <String, int>{};
  for (final r in rows) {
    // amountCents is signed: negative = expense. Take absolute magnitude.
    totals.update(
      r.categoryId,
      (v) => v + r.amountCents.abs(),
      ifAbsent: () => r.amountCents.abs(),
    );
  }
  return totals;
}

int _sumPredicted(Forecast f) =>
    f.points.fold(0, (s, p) => s + p.predictedCents);

String _fmtCents(int cents) {
  final formatted = NumberFormat('#,##0.00').format(cents.abs() / 100);
  return cents < 0 ? '-$formatted' : formatted;
}
