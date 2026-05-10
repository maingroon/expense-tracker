import 'dart:convert';
import 'dart:io';

import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/feature_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureConfig', () {
    late FeatureConfig config;

    setUp(() {
      final json = jsonDecode(
        File('test/fixtures/feature_config_sample.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      config = FeatureConfig.fromJson(json);
    });

    test('fromJson round-trip with sample fixture', () {
      final encoded = jsonEncode(config.toJson());
      final decoded = FeatureConfig.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.featureNames, equals(config.featureNames));
      expect(decoded.windowDays, equals(config.windowDays));
      expect(decoded.targetHorizon, equals(config.targetHorizon));
      expect(decoded.configVersion, equals(config.configVersion));
      expect(decoded.means.keys, equals(config.means.keys));
      expect(decoded.stds.keys, equals(config.stds.keys));
    });
  });

  group('FeatureBuilder.build (Python-contract parity)', () {
    // 20-feature config matching artefacts/feature_config.json shape, with
    // identity normalisation (mean=0, std=1) so we can assert raw values.
    FeatureConfig identityConfig({int windowDays = 60}) {
      const names = [
        'dow_0','dow_1','dow_2','dow_3','dow_4','dow_5','dow_6',
        'dom','is_weekend','is_month_start','is_month_end',
        'lag_1','lag_7','lag_14','lag_28',
        'roll_mean_7','roll_std_7','roll_mean_28','roll_std_28',
        'days_since_payday',
      ];
      return FeatureConfig(
        featureNames: names,
        means: {for (final n in names) n: 0.0},
        stds: {for (final n in names) n: 1.0},
        windowDays: windowDays,
        targetHorizon: 30,
        configVersion: 'v1',
      );
    }

    List<DailyAggregate> linearHistory({
      required DateTime endExclusive,
      required int days,
      int payDayOffsetFromEnd = -1,
    }) {
      final start = endExclusive.subtract(Duration(days: days));
      return List.generate(days, (i) {
        final date = start.add(Duration(days: i));
        final isPay = (i == days + payDayOffsetFromEnd);
        return DailyAggregate(
          date: date,
          incomeCents: isPay ? 250000 : 0,
          expenseCents: 1000 + (i % 7) * 100,
          netCents: (isPay ? 250000 : 0) - (1000 + (i % 7) * 100),
        );
      });
    }

    test('weekday one-hot fires for the right day (Tuesday)', () {
      final config = identityConfig();
      final builder = FeatureBuilder(config);
      // 2025-01-28 is a Tuesday in Dart (weekday=2 -> index 1).
      final asOf = DateTime(2025, 1, 28);
      final history =
          linearHistory(endExclusive: asOf, days: config.windowDays);
      final features = builder.build(history: history, asOf: asOf);

      // Sum of one-hot bits should equal 1
      var sum = 0.0;
      for (var i = 0; i < 7; i++) {
        sum += features[i];
      }
      expect(sum, equals(1.0));
      expect(features[1], equals(1.0)); // Tuesday
      // dom = 28 - 1 = 27
      expect(features[7], equals(27.0));
      // is_weekend, is_month_start, is_month_end all 0
      expect(features[8], equals(0.0));
      expect(features[9], equals(0.0));
      expect(features[10], equals(0.0));
    });

    test('lag_1 reads yesterday\'s expense', () {
      final config = identityConfig();
      final builder = FeatureBuilder(config);
      final asOf = DateTime(2025, 1, 28);
      final history =
          linearHistory(endExclusive: asOf, days: config.windowDays);
      final features = builder.build(history: history, asOf: asOf);

      final expectedLag1 = history.last.expenseCents.toDouble();
      // index of lag_1 in identity config order = 11
      expect(features[11], equals(expectedLag1));
    });

    test('rolling std uses population (ddof=0), not sample (ddof=1)', () {
      final config = identityConfig(windowDays: 7);
      final builder = FeatureBuilder(config);
      final asOf = DateTime(2025, 1, 28);
      final history = List.generate(7, (i) {
        return DailyAggregate(
          date: asOf.subtract(Duration(days: 7 - i)),
          incomeCents: 0,
          expenseCents: i < 3 ? 0 : 100,
          netCents: -(i < 3 ? 0 : 100),
        );
      });
      final features = builder.build(history: history, asOf: asOf);
      // mean of [0,0,0,100,100,100,100] = 400/7 ≈ 57.142857
      // pop std = sqrt(((57.14)^2*3 + (42.86)^2*4) / 7) ≈ 49.487
      // sample std would be ≈ 53.452 — test fails if pandas default sneaks in.
      // index of roll_std_7 in identity order = 16
      expect(features[16], closeTo(49.487, 0.01));
      expect(features[15], closeTo(57.142857, 0.001)); // roll_mean_7
    });

    test('days_since_payday counts back to last income-positive day', () {
      final config = identityConfig(windowDays: 10);
      final builder = FeatureBuilder(config);
      final asOf = DateTime(2025, 1, 28);
      // history[0..9] for asOf - 10 .. asOf - 1.
      // Place income at index 4: that's asOf - 6 days. days_back should be 6.
      final history = List.generate(10, (i) {
        return DailyAggregate(
          date: asOf.subtract(Duration(days: 10 - i)),
          incomeCents: i == 4 ? 1 : 0,
          expenseCents: 0,
          netCents: i == 4 ? 1 : 0,
        );
      });
      final features = builder.build(history: history, asOf: asOf);
      // days_since_payday is the last feature (index 19)
      expect(features[19], equals(6.0));
    });

    test('days_since_payday caps at window length when no income present', () {
      final config = identityConfig(windowDays: 10);
      final builder = FeatureBuilder(config);
      final asOf = DateTime(2025, 1, 28);
      final history = List.generate(10, (i) {
        return DailyAggregate(
          date: asOf.subtract(Duration(days: 10 - i)),
          incomeCents: 0,
          expenseCents: 0,
          netCents: 0,
        );
      });
      final features = builder.build(history: history, asOf: asOf);
      expect(features[19], equals(10.0));
    });

    test('returns vector of length config.featureNames.length', () {
      final config = identityConfig();
      final builder = FeatureBuilder(config);
      final asOf = DateTime(2025, 1, 28);
      final history =
          linearHistory(endExclusive: asOf, days: config.windowDays);
      final features = builder.build(history: history, asOf: asOf);
      expect(features.length, equals(config.featureNames.length));
    });
  });
}
