import 'package:expense_tracker/models/forecast_model.dart';

/// A request to the [ForecastingService] to produce a new forecast.
class ForecastRequest {
  final ForecastTarget target;

  /// Required when [target] == [ForecastTarget.expenseByCategory].
  final String? categoryId;

  /// Forecast horizon in days. Must be one of 7, 14, or 30.
  final int horizonDays;

  /// The date from which the forecast originates (exclusive end of history).
  final DateTime asOf;

  const ForecastRequest({
    required this.target,
    this.categoryId,
    required this.horizonDays,
    required this.asOf,
  });
}
