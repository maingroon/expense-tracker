import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/forecast_insight.dart';
import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/forecast_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAggregation implements AggregationService {
  _FakeAggregation(this.totalsByCat);
  final Map<String, int> totalsByCat;

  @override
  Future<List<DailyCategoryAggregate>> getDailyByCategory({
    required DateTime from,
    required DateTime to,
    List<String>? categoryIds,
  }) async {
    final out = <DailyCategoryAggregate>[];
    for (final entry in totalsByCat.entries) {
      if (categoryIds != null && !categoryIds.contains(entry.key)) continue;
      out.add(DailyCategoryAggregate(
        date: from,
        categoryId: entry.key,
        // amountCents is signed: negative = expense.
        amountCents: -entry.value,
        txCount: 1,
      ));
    }
    return out;
  }

  // Unused here.
  @override
  Future<List<DailyAggregate>> getDailyTotals({
    required DateTime from,
    required DateTime to,
  }) async => [];

  @override
  Future<List<DailyAggregate>> getDailyBalance({
    required DateTime from,
    required DateTime to,
  }) async => [];

  @override
  Future<DateTime?> earliestTransactionDate() async => null;

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Forecast _balanceForecast({
  required int firstPredicted,
  required int lastPredicted,
  required int sigmaCents,
}) {
  final base = DateTime(2026, 4, 1);
  final lo1 = (firstPredicted - 1.28 * sigmaCents).round();
  final hi1 = (firstPredicted + 1.28 * sigmaCents).round();
  final loN = (lastPredicted - 1.28 * sigmaCents).round();
  final hiN = (lastPredicted + 1.28 * sigmaCents).round();
  return Forecast.create(
    target: ForecastTarget.balance,
    horizonDays: 7,
    modelName: 't', modelVersion: '0',
    points: [
      ForecastPoint(date: base, predictedCents: firstPredicted,
          lowerCents: lo1, upperCents: hi1),
      for (var i = 1; i < 6; i++)
        ForecastPoint(
          date: base.add(Duration(days: i)),
          predictedCents:
              ((firstPredicted * (6 - i) + lastPredicted * i) / 6).round(),
          lowerCents: lo1, upperCents: hi1,
        ),
      ForecastPoint(
        date: base.add(const Duration(days: 6)),
        predictedCents: lastPredicted,
        lowerCents: loN, upperCents: hiN,
      ),
    ],
  );
}

Forecast _flatExpenseForecast({
  required String categoryId,
  required int dailyCents,
  int days = 7,
}) {
  final base = DateTime(2026, 4, 1);
  return Forecast.create(
    target: ForecastTarget.expenseByCategory,
    categoryId: categoryId,
    horizonDays: days,
    modelName: 't', modelVersion: '0',
    points: List.generate(days, (i) => ForecastPoint(
          date: base.add(Duration(days: i)),
          predictedCents: dailyCents,
        )),
  );
}

Category _cat(String id, String name) => Category(
      id: id, icon: Icons.shopping_cart, color: Colors.blue,
      name: name, type: CategoryType.expense, position: 0,
    );

void main() {
  test('overdraft warning surfaces when end-of-horizon risk ≥ threshold', () async {
    final balance = _balanceForecast(
      firstPredicted: 1000, lastPredicted: 0, sigmaCents: 1000,
    ); // P(end < 0) ≈ 0.5
    final insights = await buildInsights(
      balanceForecast: balance,
      categoryForecasts: const [],
      aggregation: _FakeAggregation(const {}),
      asOf: DateTime(2026, 4, 1),
    );
    expect(insights, isNotEmpty);
    expect(insights.first.title, contains('overdraft'));
    expect(insights.first.severity, InsightSeverity.danger);
  });

  test('no overdraft warning when risk is well below threshold', () async {
    final balance = _balanceForecast(
      firstPredicted: 100000, lastPredicted: 100000, sigmaCents: 100,
    );
    final insights = await buildInsights(
      balanceForecast: balance,
      categoryForecasts: const [],
      aggregation: _FakeAggregation(const {}),
      asOf: DateTime(2026, 4, 1),
    );
    expect(insights.where((i) => i.title.contains('overdraft')), isEmpty);
  });

  test('positive saving insight when balance trends up', () async {
    final balance = _balanceForecast(
      firstPredicted: 100000, lastPredicted: 200000, sigmaCents: 1000,
    );
    final insights = await buildInsights(
      balanceForecast: balance,
      categoryForecasts: const [],
      aggregation: _FakeAggregation(const {}),
      asOf: DateTime(2026, 4, 1),
    );
    expect(insights.any((i) => i.title.contains('save')), isTrue);
  });

  test('over-budget category insight for ratio ≥ 1.20', () async {
    // 7-day projected = 7 × 100 = 700. baseline 30d × 7/30 = 30 × 7/30 = 7.
    // ratio = 700 / 7 = 100 → over.
    final cat = _cat('groceries', 'Groceries');
    final balance = _balanceForecast(
      firstPredicted: 100000, lastPredicted: 100000, sigmaCents: 100,
    );
    final insights = await buildInsights(
      balanceForecast: balance,
      categoryForecasts: [(category: cat, forecast: _flatExpenseForecast(
        categoryId: cat.id, dailyCents: 100,
      ))],
      aggregation: _FakeAggregation(const {'groceries': 30}),
      asOf: DateTime(2026, 4, 1),
    );
    expect(
      insights.any((i) =>
          i.title.contains('Groceries') && i.title.contains('+')),
      isTrue,
    );
  });

  test('under-budget category insight for ratio ≤ 0.80', () async {
    // 7-day projected = 7 × 1 = 7. baseline 30d × 7/30 = 1000 × 7/30 ≈ 233.
    // ratio ≈ 0.03 → under.
    final cat = _cat('shopping', 'Shopping');
    final balance = _balanceForecast(
      firstPredicted: 100000, lastPredicted: 100000, sigmaCents: 100,
    );
    final insights = await buildInsights(
      balanceForecast: balance,
      categoryForecasts: [(category: cat, forecast: _flatExpenseForecast(
        categoryId: cat.id, dailyCents: 1,
      ))],
      aggregation: _FakeAggregation(const {'shopping': 1000}),
      asOf: DateTime(2026, 4, 1),
    );
    expect(
      insights.any((i) =>
          i.title.contains('Shopping') && i.severity == InsightSeverity.positive),
      isTrue,
    );
  });

  test('on-track ratios produce no category insight', () async {
    // Projected 7×100=700; baseline 3000×7/30=700; ratio=1.0 → on-track.
    final cat = _cat('groceries', 'Groceries');
    final balance = _balanceForecast(
      firstPredicted: 100000, lastPredicted: 100000, sigmaCents: 100,
    );
    final insights = await buildInsights(
      balanceForecast: balance,
      categoryForecasts: [(category: cat, forecast: _flatExpenseForecast(
        categoryId: cat.id, dailyCents: 100,
      ))],
      aggregation: _FakeAggregation(const {'groceries': 3000}),
      asOf: DateTime(2026, 4, 1),
    );
    expect(insights.where((i) => i.title.contains('Groceries')), isEmpty);
  });

  test('insights ranked by severity, capped at kMaxInsights', () async {
    // overdraft (danger) + over-budget Groceries (warning) + saving balance (positive)
    // should produce 3 in order: danger, warning, positive.
    final balance = _balanceForecast(
      firstPredicted: 1000, lastPredicted: 0, sigmaCents: 1000,
    );
    final cat = _cat('groceries', 'Groceries');
    final insights = await buildInsights(
      balanceForecast: balance,
      categoryForecasts: [(category: cat, forecast: _flatExpenseForecast(
        categoryId: cat.id, dailyCents: 100,
      ))],
      aggregation: _FakeAggregation(const {'groceries': 30}),
      asOf: DateTime(2026, 4, 1),
    );
    expect(insights.length, lessThanOrEqualTo(kMaxInsights));
    // Must be sorted descending by severity.
    for (var i = 1; i < insights.length; i++) {
      expect(
        insights[i].severity.index,
        lessThanOrEqualTo(insights[i - 1].severity.index),
      );
    }
  });
}
