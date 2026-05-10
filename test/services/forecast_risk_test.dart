import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/services/forecast_risk.dart';
import 'package:flutter_test/flutter_test.dart';

Forecast _balance({required List<({int predicted, int lower})> rows}) {
  final base = DateTime(2026, 4, 1);
  return Forecast.create(
    target: ForecastTarget.balance,
    horizonDays: 7,
    modelName: 'test',
    modelVersion: '0',
    points: List.generate(7, (i) {
      final r = rows[i.clamp(0, rows.length - 1)];
      final upper = 2 * r.predicted - r.lower;
      return ForecastPoint(
        date: base.add(Duration(days: i)),
        predictedCents: r.predicted,
        lowerCents: r.lower,
        upperCents: upper,
      );
    }),
  );
}

void main() {
  group('normalCdf', () {
    test('Φ(0) ≈ 0.5', () {
      expect(normalCdf(0), closeTo(0.5, 1e-3));
    });
    test('Φ(1.96) ≈ 0.975', () {
      expect(normalCdf(1.96), closeTo(0.975, 1e-3));
    });
    test('Φ(-1.96) ≈ 0.025', () {
      expect(normalCdf(-1.96), closeTo(0.025, 1e-3));
    });
    test('symmetry: Φ(z) + Φ(-z) ≈ 1', () {
      for (final z in [0.3, 0.7, 1.5, 2.5]) {
        expect(normalCdf(z) + normalCdf(-z), closeTo(1.0, 1e-6));
      }
    });
  });

  group('overdraftRisk', () {
    test('all-positive predictions with tight CI → near-zero risk', () {
      final f = _balance(rows: List.generate(7, (_) =>
          (predicted: 100000, lower: 99000)));
      final r = overdraftRisk(f);
      expect(r.endOfHorizon, lessThan(1e-6));
      expect(r.anyDay, lessThan(1e-6));
    });

    test('predicted_H = 0 with positive σ → end-of-horizon ≈ 0.5', () {
      final f = _balance(rows: List.generate(7, (_) =>
          (predicted: 0, lower: -1280)));
      final r = overdraftRisk(f);
      expect(r.endOfHorizon, closeTo(0.5, 1e-3));
      expect(r.anyDay, closeTo(0.5, 1e-3));
    });

    test('CI absent → risk is 0', () {
      final f = Forecast.create(
        target: ForecastTarget.balance,
        horizonDays: 7,
        modelName: 'test',
        modelVersion: '0',
        points: List.generate(7, (i) => ForecastPoint(
              date: DateTime(2026, 4, 1).add(Duration(days: i)),
              predictedCents: -10000,
            )),
      );
      final r = overdraftRisk(f);
      expect(r.endOfHorizon, 0.0);
      expect(r.anyDay, 0.0);
    });

    test('anyDay is at least endOfHorizon when an earlier day is worse', () {
      final f = _balance(rows: [
        (predicted: 100, lower: -2000),     // day 0: very risky
        (predicted: 5000, lower: 4000),
        (predicted: 5000, lower: 4000),
        (predicted: 5000, lower: 4000),
        (predicted: 5000, lower: 4000),
        (predicted: 5000, lower: 4000),
        (predicted: 10000, lower: 9000),    // day 6: safe
      ]);
      final r = overdraftRisk(f);
      expect(r.anyDay, greaterThan(r.endOfHorizon));
      expect(r.endOfHorizon, lessThan(0.01));
      expect(r.anyDay, greaterThan(0.4));
    });
  });

  group('thresholdBreachProbability', () {
    test('predicted = threshold with σ > 0 → ≈ 0.5', () {
      final f = _balance(rows: List.generate(7, (_) =>
          (predicted: 5000, lower: 4000)));
      expect(thresholdBreachProbability(f, 5000), closeTo(0.5, 1e-3));
    });

    test('threshold far below predicted → ≈ 0', () {
      final f = _balance(rows: List.generate(7, (_) =>
          (predicted: 100000, lower: 99000)));
      expect(thresholdBreachProbability(f, 0), lessThan(1e-6));
    });

    test('empty forecast → 0', () {
      final f = Forecast(
        id: 'x',
        generatedAt: DateTime(2026, 4, 1),
        target: ForecastTarget.balance,
        horizonDays: 7,
        modelName: 'test',
        modelVersion: '0',
        points: const [],
      );
      expect(thresholdBreachProbability(f, 0), 0.0);
    });
  });
}
