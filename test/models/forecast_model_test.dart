import 'dart:convert';

import 'package:expense_tracker/models/forecast_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForecastPoint', () {
    test('round-trip JSON with CI', () {
      final point = ForecastPoint(
        date: DateTime(2026, 4, 1),
        predictedCents: 5000,
        lowerCents: 4000,
        upperCents: 6000,
      );
      final decoded = ForecastPoint.fromJson(point.toJson());
      expect(decoded, equals(point));
    });

    test('round-trip JSON without CI', () {
      final point = ForecastPoint(
        date: DateTime(2026, 4, 1),
        predictedCents: 5000,
      );
      final json = point.toJson();
      expect(json.containsKey('lower_cents'), isFalse);
      expect(json.containsKey('upper_cents'), isFalse);
      final decoded = ForecastPoint.fromJson(json);
      expect(decoded.lowerCents, isNull);
      expect(decoded.upperCents, isNull);
    });

    test('equality', () {
      final a = ForecastPoint(
        date: DateTime(2026, 4, 1),
        predictedCents: 5000,
        lowerCents: 4000,
        upperCents: 6000,
      );
      final b = ForecastPoint(
        date: DateTime(2026, 4, 1),
        predictedCents: 5000,
        lowerCents: 4000,
        upperCents: 6000,
      );
      expect(a, equals(b));
    });
  });

  group('Forecast', () {
    Forecast makeForecast({
      ForecastTarget target = ForecastTarget.expenseTotal,
      String? categoryId,
      int horizonDays = 7,
      bool withCi = true,
    }) {
      return Forecast.create(
        target: target,
        categoryId: categoryId,
        horizonDays: horizonDays,
        modelName: 'naive',
        modelVersion: '1.0.0',
        points: List.generate(
          horizonDays,
          (i) => ForecastPoint(
            date: DateTime(2026, 4, 1 + i),
            predictedCents: 5000,
            lowerCents: withCi ? 4000 : null,
            upperCents: withCi ? 6000 : null,
          ),
        ),
      );
    }

    test('round-trip JSON expenseTotal with CI', () {
      final f = makeForecast(horizonDays: 7, withCi: true);
      final decoded = Forecast.fromJson(f.toJson());
      expect(decoded.id, equals(f.id));
      expect(decoded.target, equals(ForecastTarget.expenseTotal));
      expect(decoded.points.length, equals(7));
      expect(decoded.points.first.lowerCents, equals(4000));
    });

    test('round-trip JSON expenseByCategory without CI', () {
      final f = makeForecast(
        target: ForecastTarget.expenseByCategory,
        categoryId: 'cat-123',
        horizonDays: 14,
        withCi: false,
      );
      final decoded = Forecast.fromJson(f.toJson());
      expect(decoded.categoryId, equals('cat-123'));
      expect(decoded.target, equals(ForecastTarget.expenseByCategory));
      expect(decoded.points.first.lowerCents, isNull);
    });

    test('round-trip JSON balance with CI', () {
      final f = makeForecast(target: ForecastTarget.balance, horizonDays: 30);
      final str = jsonEncode(f.toJson());
      final decoded = Forecast.fromJson(jsonDecode(str) as Map<String, dynamic>);
      expect(decoded.target, equals(ForecastTarget.balance));
      expect(decoded.horizonDays, equals(30));
    });

    test('equality', () {
      final f = makeForecast(horizonDays: 7);
      final decoded = Forecast.fromJson(f.toJson());
      expect(decoded, equals(f));
    });

    test('Forecast.create throws ArgumentError for invalid horizonDays', () {
      expect(
        () => Forecast.create(
          target: ForecastTarget.expenseTotal,
          horizonDays: 10,
          modelName: 'naive',
          modelVersion: '1.0.0',
          points: [],
        ),
        throwsArgumentError,
      );
    });

    test('Forecast.fromJson throws ArgumentError for invalid horizonDays', () {
      final f = makeForecast(horizonDays: 7);
      final json = f.toJson();
      json['horizon_days'] = 10;
      expect(() => Forecast.fromJson(json), throwsArgumentError);
    });

    for (final valid in [7, 14, 30]) {
      test('horizonDays $valid is accepted', () {
        expect(
          () => Forecast.create(
            target: ForecastTarget.expenseTotal,
            horizonDays: valid,
            modelName: 'naive',
            modelVersion: '1.0.0',
            points: [],
          ),
          returnsNormally,
        );
      });
    }
  });
}
