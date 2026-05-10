import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Parsed contents of `assets/models/coeffs.json`.
///
/// The JSON schema is fixed by the implementation plan §B5.2; if you change it
/// here, regenerate the artefact in `expense-forecasting-research/` and rerun
/// the parity gate.
class RidgeCoefficients {
  final String modelName;
  final String modelVersion;
  final double intercept;
  final List<String> featureOrder;
  final List<double> weights;
  final int outputHorizonDays;
  final String outputUnit;
  final double postScaleMean;
  final double postScaleStd;
  final double residualStd;

  const RidgeCoefficients({
    required this.modelName,
    required this.modelVersion,
    required this.intercept,
    required this.featureOrder,
    required this.weights,
    required this.outputHorizonDays,
    required this.outputUnit,
    required this.postScaleMean,
    required this.postScaleStd,
    required this.residualStd,
  });

  factory RidgeCoefficients.fromJson(Map<String, dynamic> json) {
    final coefs = (json['coefficients'] as List).cast<Map<String, dynamic>>();
    return RidgeCoefficients(
      modelName: json['model_name'] as String,
      modelVersion: json['model_version'] as String,
      intercept: (json['intercept'] as num).toDouble(),
      featureOrder: coefs.map((c) => c['name'] as String).toList(),
      weights: coefs.map((c) => (c['weight'] as num).toDouble()).toList(),
      outputHorizonDays: json['output_horizon_days'] as int,
      outputUnit: json['output_unit'] as String,
      postScaleMean:
          ((json['post_scale'] as Map)['mean'] as num).toDouble(),
      postScaleStd:
          ((json['post_scale'] as Map)['std'] as num).toDouble(),
      residualStd: (json['residual_std'] as num).toDouble(),
    );
  }

  static RidgeCoefficients fromJsonString(String s) =>
      RidgeCoefficients.fromJson(json.decode(s) as Map<String, dynamic>);

  static Future<RidgeCoefficients> loadFromAssets({
    String assetPath = 'assets/models/coeffs.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    return fromJsonString(raw);
  }
}
