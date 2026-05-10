import 'dart:convert';
import 'dart:io';

import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/feature_builder.dart';
import 'package:expense_tracker/services/ridge_coefficients.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads an asset directly from the package's `assets/` tree.
///
/// We deliberately avoid `rootBundle` — when there is no widget pump cycle,
/// `rootBundle.loadString` can hang in `testWidgets` because asset resolution
/// goes through Flutter's binary messenger. Reading the file directly keeps
/// the test fast and host-independent.
String _readAsset(String relativePath) =>
    File(relativePath).readAsStringSync();

void main() {
  group('Golden parity (Python ↔ Dart)', () {
    late List<dynamic> cases;
    late FeatureConfig config;
    late RidgeCoefficients coefs;
    late FeatureBuilder builder;

    setUpAll(() {
      cases = jsonDecode(_readAsset('assets/test/golden_forecasts.json'))
          as List<dynamic>;
      if (cases.isEmpty) return;
      config = FeatureConfig.fromJsonString(
          _readAsset('assets/models/feature_config.json'));
      coefs = RidgeCoefficients.fromJsonString(
          _readAsset('assets/models/coeffs.json'));
      builder = FeatureBuilder(config);
    });

    test('artefacts agree on feature names and order', () {
      if (cases.isEmpty) return;
      expect(coefs.featureOrder, equals(config.featureNames),
          reason: 'feature_config and coeffs must agree on feature order');
    });

    test('every golden case matches features (1e-4) and prediction (±1 cent)',
        () {
      if (cases.isEmpty) {
        // Empty fixture is the placeholder shipped before B5 lands.
        // ignore: avoid_print
        print('WARNING: assets/test/golden_forecasts.json is empty.');
        return;
      }

      const featureTolerance = 1e-4;
      const predictionToleranceCents = 1;

      for (final raw in cases) {
        final c = raw as Map<String, dynamic>;
        final caseId = c['case_id'] as String;
        final asOf =
            DateTime.parse((c['as_of'] as String).replaceAll('Z', ''));
        final expectedFeatures = (c['expected_features'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
        final expectedPrediction = c['expected_prediction_cents'] as int;
        final caseConfigVersion = c['feature_config_version'] as String;

        expect(caseConfigVersion, equals(config.configVersion),
            reason: '$caseId: config_version mismatch');

        final history = (c['history'] as List).map((h) {
          final hm = h as Map<String, dynamic>;
          return DailyAggregate(
            date: DateTime.parse(hm['date'] as String),
            incomeCents: hm['income_cents'] as int,
            expenseCents: hm['expense_cents'] as int,
            netCents: hm['net_cents'] as int,
          );
        }).toList();

        final features = builder.build(history: history, asOf: asOf);
        expect(features.length, equals(expectedFeatures.length),
            reason: '$caseId: feature vector length mismatch');
        for (var i = 0; i < features.length; i++) {
          final diff = (features[i] - expectedFeatures[i]).abs();
          expect(diff, lessThanOrEqualTo(featureTolerance),
              reason:
                  '$caseId feature[$i] (${config.featureNames[i]}): '
                  '${features[i]} vs expected ${expectedFeatures[i]} '
                  '(diff=$diff)');
        }

        var normPred = coefs.intercept;
        for (var i = 0; i < features.length; i++) {
          normPred += coefs.weights[i] * features[i];
        }
        final cents =
            (normPred * coefs.postScaleStd + coefs.postScaleMean).round();
        final predicted = cents < 0 ? 0 : cents;
        final diff = (predicted - expectedPrediction).abs();
        expect(diff, lessThanOrEqualTo(predictionToleranceCents),
            reason: '$caseId prediction: $predicted vs expected '
                '$expectedPrediction (diff=$diff cents)');
      }
    });
  });
}
