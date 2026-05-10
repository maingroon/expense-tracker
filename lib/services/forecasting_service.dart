import 'dart:math';

import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/models/forecast_request_model.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'package:expense_tracker/services/forecasting_exceptions.dart';

abstract class ForecastingService {
  /// Runs a forecast and persists the result via [ForecastRepository].
  Future<Forecast> forecast(ForecastRequest request);

  /// Whether the active model has enough history to be trustworthy.
  /// Returns `false` during cold start (no transaction history).
  Future<bool> get hasEnoughHistory;

  /// Number of days of transaction history available, capped at 365.
  Future<int> get availableHistoryDays;
}

/// Stub implementation using last-30-day averages — no ML model required.
///
/// Produces deterministic predictions for any given transaction history.
/// The real ML-backed service will replace this without changing callers.
class NaiveForecastingService implements ForecastingService {
  NaiveForecastingService(this._aggregation, this._repository);

  final AggregationService _aggregation;
  final ForecastRepository _repository;

  static const _modelName = 'naive';
  static const _modelVersion = '1.0.0';
  static const _historyWindow = 30;

  /// Minimum days of history the stub requires to produce a forecast.
  static const _minRequiredDays = 1;

  @override
  Future<bool> get hasEnoughHistory async {
    return await availableHistoryDays >= _minRequiredDays;
  }

  @override
  Future<int> get availableHistoryDays async {
    final earliest = await _aggregation.earliestTransactionDate();
    if (earliest == null) return 0;
    final days = DateTime.now().difference(earliest).inDays;
    return days.clamp(0, 365);
  }

  @override
  Future<Forecast> forecast(ForecastRequest request) async {
    final availDays = await availableHistoryDays;
    if (availDays < _minRequiredDays) {
      throw InsufficientHistoryException(
        availableDays: availDays,
        requiredDays: _minRequiredDays,
      );
    }

    final asOf = _midnight(request.asOf);
    final historyEnd = asOf.subtract(const Duration(days: 1));
    final historyStart = historyEnd.subtract(
      Duration(days: _historyWindow - 1),
    );

    final List<ForecastPoint> points;
    switch (request.target) {
      case ForecastTarget.expenseTotal:
        points = await _forecastExpense(
          asOf: asOf,
          historyStart: historyStart,
          historyEnd: historyEnd,
          horizonDays: request.horizonDays,
          categoryId: null,
        );
      case ForecastTarget.balance:
        points = await _forecastBalance(
          asOf: asOf,
          historyStart: historyStart,
          historyEnd: historyEnd,
          horizonDays: request.horizonDays,
        );
      case ForecastTarget.expenseByCategory:
        points = await _forecastExpense(
          asOf: asOf,
          historyStart: historyStart,
          historyEnd: historyEnd,
          horizonDays: request.horizonDays,
          categoryId: request.categoryId,
        );
    }

    final result = Forecast.create(
      target: request.target,
      categoryId: request.categoryId,
      horizonDays: request.horizonDays,
      modelName: _modelName,
      modelVersion: _modelVersion,
      points: points,
    );

    await _repository.save(result);
    return result;
  }

  Future<List<ForecastPoint>> _forecastExpense({
    required DateTime asOf,
    required DateTime historyStart,
    required DateTime historyEnd,
    required int horizonDays,
    required String? categoryId,
  }) async {
    List<int> amounts;

    if (categoryId != null) {
      final catHistory = await _aggregation.getDailyByCategory(
        from: historyStart,
        to: historyEnd,
        categoryIds: [categoryId],
      );
      final byDay = <String, int>{};
      for (final a in catHistory) {
        byDay[_dateKey(a.date)] = a.amountCents;
      }
      amounts = _dayRange(historyStart, historyEnd)
          .map((d) => (byDay[_dateKey(d)] ?? 0).abs())
          .toList();
    } else {
      final history = await _aggregation.getDailyTotals(
        from: historyStart,
        to: historyEnd,
      );
      amounts = history.map((d) => d.expenseCents).toList();
    }

    final mean = _mean(amounts);
    final std = _std(amounts, mean);

    return List.generate(horizonDays, (i) {
      final predicted = mean.round();
      final ci = std.round();
      return ForecastPoint(
        date: asOf.add(Duration(days: i)),
        predictedCents: predicted,
        lowerCents: max(0, predicted - ci),
        upperCents: predicted + ci,
      );
    });
  }

  Future<List<ForecastPoint>> _forecastBalance({
    required DateTime asOf,
    required DateTime historyStart,
    required DateTime historyEnd,
    required int horizonDays,
  }) async {
    final dailyTotals = await _aggregation.getDailyTotals(
      from: historyStart,
      to: historyEnd,
    );
    final nets = dailyTotals.map((d) => d.netCents).toList();
    final meanNet = _mean(nets);
    final stdNet = _std(nets, meanNet);

    final balanceSeries = await _aggregation.getDailyBalance(
      from: historyEnd,
      to: historyEnd,
    );
    final currentBalance =
        balanceSeries.isEmpty ? 0 : balanceSeries.first.netCents;

    return List.generate(horizonDays, (i) {
      final d = i + 1;
      final predicted = (currentBalance + meanNet * d).round();
      final ci = (stdNet * sqrt(d.toDouble())).round();
      return ForecastPoint(
        date: asOf.add(Duration(days: i)),
        predictedCents: predicted,
        lowerCents: predicted - ci,
        upperCents: predicted + ci,
      );
    });
  }

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static List<DateTime> _dayRange(DateTime from, DateTime to) {
    final days = <DateTime>[];
    var cur = from;
    while (!cur.isAfter(to)) {
      days.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return days;
  }

  static double _mean(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _std(List<int> values, double mean) {
    if (values.length < 2) return 0;
    final variance = values
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }
}
