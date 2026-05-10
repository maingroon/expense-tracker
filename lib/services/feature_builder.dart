import 'dart:convert';
import 'dart:math' as math;

import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Configuration that describes how to build model input features.
class FeatureConfig {
  /// Ordered list of feature names (e.g., ["dow_0", "lag_1", "lag_7"]).
  final List<String> featureNames;

  /// Per-feature mean used for z-score normalisation.
  final Map<String, double> means;

  /// Per-feature standard deviation used for z-score normalisation.
  final Map<String, double> stds;

  /// Number of historical days required to build a single feature vector.
  final int windowDays;

  /// Forecast horizon the model was trained to predict.
  final int targetHorizon;

  final String configVersion;

  const FeatureConfig({
    required this.featureNames,
    required this.means,
    required this.stds,
    required this.windowDays,
    required this.targetHorizon,
    required this.configVersion,
  });

  factory FeatureConfig.fromJson(Map<String, dynamic> json) => FeatureConfig(
        featureNames: List<String>.from(json['feature_names'] as List),
        means: Map<String, double>.from(
          (json['means'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        ),
        stds: Map<String, double>.from(
          (json['stds'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        ),
        windowDays: json['window_days'] as int,
        targetHorizon: json['target_horizon'] as int,
        configVersion: json['config_version'] as String,
      );

  Map<String, dynamic> toJson() => {
        'feature_names': featureNames,
        'means': means,
        'stds': stds,
        'window_days': windowDays,
        'target_horizon': targetHorizon,
        'config_version': configVersion,
      };

  static FeatureConfig fromJsonString(String s) =>
      FeatureConfig.fromJson(json.decode(s) as Map<String, dynamic>);

  /// Loads `assets/models/feature_config.json` once and caches it.
  static Future<FeatureConfig> loadFromAssets({
    String assetPath = 'assets/models/feature_config.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    return fromJsonString(raw);
  }
}

/// Transforms a [config.windowDays]-day window of [DailyAggregate] history into
/// a normalised model input vector.
///
/// The implementation mirrors `expense-forecasting-research/src/features/builder.py`
/// byte-for-byte. If you change either side, regenerate
/// `assets/models/feature_config.json` and re-run `golden_test.dart` — drift
/// surfaces there immediately.
class FeatureBuilder {
  FeatureBuilder(this.config);
  final FeatureConfig config;

  /// Builds a single feature vector from the last [config.windowDays] entries
  /// of [history], which must be sorted ascending and end at `asOf - 1 day`.
  ///
  /// Length of the returned list equals `config.featureNames.length`.
  List<double> build({
    required List<DailyAggregate> history,
    required DateTime asOf,
  }) {
    final asOfDay = DateTime(asOf.year, asOf.month, asOf.day);
    final raw = _computeRaw(history, asOfDay);
    final out = List<double>.filled(config.featureNames.length, 0);
    for (var i = 0; i < config.featureNames.length; i++) {
      final name = config.featureNames[i];
      final v = raw[name] ?? 0.0;
      final m = config.means[name] ?? 0.0;
      final s = math.max(config.stds[name] ?? 1.0, 1e-9);
      out[i] = (v - m) / s;
    }
    return out;
  }

  /// Returns un-normalised feature values keyed by name. Exposed for tests.
  Map<String, double> _computeRaw(
    List<DailyAggregate> history,
    DateTime asOf,
  ) {
    final raw = <String, double>{};

    // -------- Calendar features for asOf --------
    // Python's asof.weekday(): 0 = Monday, 6 = Sunday.
    // Dart's DateTime.weekday:  1 = Monday, 7 = Sunday.
    final dow = asOf.weekday - 1;        // 0..6
    for (var i = 0; i < 7; i++) {
      raw['dow_$i'] = (i == dow) ? 1.0 : 0.0;
    }
    raw['dom'] = (asOf.day - 1).toDouble();          // 0..30
    raw['is_weekend'] = (dow >= 5) ? 1.0 : 0.0;
    raw['is_month_start'] = (asOf.day <= 3) ? 1.0 : 0.0;
    final lastDay = DateTime(asOf.year, asOf.month + 1, 0).day;
    raw['is_month_end'] = (asOf.day >= lastDay - 2) ? 1.0 : 0.0;

    // -------- Lags --------
    // history.length should equal config.windowDays, with history.last == asOf - 1 day.
    final n = history.length;
    for (final lag in const [1, 7, 14, 28]) {
      raw['lag_$lag'] =
          (n >= lag) ? history[n - lag].expenseCents.toDouble() : 0.0;
    }

    // -------- Rolling mean/std (population, ddof=0) --------
    for (final w in const [7, 28]) {
      final start = (n >= w) ? n - w : 0;
      final slice = history
          .sublist(start, n)
          .map((d) => d.expenseCents.toDouble())
          .toList(growable: false);
      raw['roll_mean_$w'] = _mean(slice);
      raw['roll_std_$w'] = _populationStd(slice);
    }

    // -------- days_since_payday --------
    // Scan backward for the last day with positive income inside the window.
    // Window spans (asOf - windowDays) .. (asOf - 1), so the last index aligns
    // with asOf - 1 day. days_back = (n - 1 - last_income_idx) + 1 = n - last_income_idx.
    var lastIncomeIdx = -1;
    for (var i = n - 1; i >= 0; i--) {
      if (history[i].incomeCents > 0) {
        lastIncomeIdx = i;
        break;
      }
    }
    raw['days_since_payday'] =
        (lastIncomeIdx >= 0) ? (n - lastIncomeIdx).toDouble() : n.toDouble();

    return raw;
  }

  static double _mean(List<double> xs) {
    if (xs.isEmpty) return 0;
    var s = 0.0;
    for (final x in xs) {
      s += x;
    }
    return s / xs.length;
  }

  /// Population standard deviation (ddof=0) — matches Python's `np.std` default.
  /// Pandas defaults to ddof=1; do not use that here.
  static double _populationStd(List<double> xs) {
    if (xs.isEmpty) return 0;
    final m = _mean(xs);
    var sq = 0.0;
    for (final x in xs) {
      final d = x - m;
      sq += d * d;
    }
    return math.sqrt(sq / xs.length);
  }
}
