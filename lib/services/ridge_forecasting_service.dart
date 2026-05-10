import 'dart:math' as math;

import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/models/forecast_request_model.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/feature_builder.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'package:expense_tracker/services/forecasting_exceptions.dart';
import 'package:expense_tracker/services/forecasting_service.dart';
import 'package:expense_tracker/services/ridge_coefficients.dart';

/// On-device ridge regressor backing [ForecastTarget.expenseTotal].
///
/// Loads `assets/models/feature_config.json` and `assets/models/coeffs.json`
/// once, then iterates the same recursive multi-step loop that
/// `expense-forecasting-research/src/models/recursive.py` uses — feeding each
/// step's prediction back as the next day's history so future-day lag features
/// stay self-consistent.
///
/// The other two targets ([ForecastTarget.balance] and
/// [ForecastTarget.expenseByCategory]) fall through to [_fallback] because the
/// ridge model is trained on daily expense only.
class RidgeForecastingService implements ForecastingService {
  RidgeForecastingService(
    this._aggregation,
    this._repository, {
    required ForecastingService fallback,
  }) : _fallback = fallback;

  final AggregationService _aggregation;
  final ForecastRepository _repository;
  final ForecastingService _fallback;

  // 80 % confidence band: ±1.28σ assuming Gaussian residuals.
  // Used by the UI to render the shaded band around the predicted line.
  static const double _ciZ = 1.28;

  FeatureConfig? _config;
  RidgeCoefficients? _coefs;
  FeatureBuilder? _builder;
  Future<void>? _loading;

  Future<void> _ensureLoaded() {
    return _loading ??= () async {
      final results = await Future.wait([
        FeatureConfig.loadFromAssets(),
        RidgeCoefficients.loadFromAssets(),
      ]);
      _config = results[0] as FeatureConfig;
      _coefs = results[1] as RidgeCoefficients;
      _builder = FeatureBuilder(_config!);

      // Sanity: feature order in coeffs must match feature_config.
      final expected = _config!.featureNames;
      final got = _coefs!.featureOrder;
      if (expected.length != got.length) {
        throw StateError(
          'Ridge artefact mismatch: feature_config has ${expected.length} '
          'features but coeffs.json has ${got.length}.',
        );
      }
      for (var i = 0; i < expected.length; i++) {
        if (expected[i] != got[i]) {
          throw StateError(
            'Ridge artefact mismatch at index $i: '
            'feature_config="${expected[i]}" vs coeffs="${got[i]}".',
          );
        }
      }
    }();
  }

  @override
  Future<int> get availableHistoryDays async {
    final earliest = await _aggregation.earliestTransactionDate();
    if (earliest == null) return 0;
    final days = DateTime.now().difference(earliest).inDays;
    return days.clamp(0, 365);
  }

  @override
  Future<bool> get hasEnoughHistory async {
    await _ensureLoaded();
    return await availableHistoryDays >= _config!.windowDays;
  }

  @override
  Future<Forecast> forecast(ForecastRequest request) async {
    if (request.target != ForecastTarget.expenseTotal) {
      return _fallback.forecast(request);
    }
    await _ensureLoaded();
    final config = _config!;
    final coefs = _coefs!;
    final builder = _builder!;

    final asOf = _midnight(request.asOf);
    final available = await availableHistoryDays;
    if (available < config.windowDays) {
      throw InsufficientHistoryException(
        availableDays: available,
        requiredDays: config.windowDays,
      );
    }

    // Pull the trailing window ending the day before asOf.
    final historyEnd = asOf.subtract(const Duration(days: 1));
    final historyStart =
        historyEnd.subtract(Duration(days: config.windowDays - 1));
    final history = await _aggregation.getDailyTotals(
      from: historyStart,
      to: historyEnd,
    );

    // Recursive multi-step forecast, mirroring src/models/recursive.py.
    final rolling = List<DailyAggregate>.from(history);
    final points = <ForecastPoint>[];
    final ci = (_ciZ * coefs.residualStd).round();

    for (var h = 0; h < request.horizonDays; h++) {
      final targetDate = asOf.add(Duration(days: h));
      // Feed the trailing windowDays entries (most recent at the end).
      final window = rolling.sublist(rolling.length - config.windowDays);
      final features = builder.build(history: window, asOf: targetDate);

      var normPred = coefs.intercept;
      for (var i = 0; i < features.length; i++) {
        normPred += coefs.weights[i] * features[i];
      }
      final cents =
          (normPred * coefs.postScaleStd + coefs.postScaleMean).round();
      final predicted = math.max(0, cents);

      points.add(ForecastPoint(
        date: targetDate,
        predictedCents: predicted,
        lowerCents: math.max(0, predicted - ci),
        upperCents: predicted + ci,
      ));

      // Append our prediction to history so subsequent lag/rolling features
      // remain self-consistent.
      rolling.add(DailyAggregate(
        date: targetDate,
        incomeCents: 0,
        expenseCents: predicted,
        netCents: -predicted,
      ));
    }

    final result = Forecast.create(
      target: request.target,
      categoryId: request.categoryId,
      horizonDays: request.horizonDays,
      modelName: coefs.modelName,
      modelVersion: coefs.modelVersion,
      points: points,
    );
    await _repository.save(result);
    return result;
  }

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
}
