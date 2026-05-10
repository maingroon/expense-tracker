import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum ForecastTarget {
  expenseTotal,
  balance,
  expenseByCategory,
}

/// A single day's predicted value within a [Forecast].
class ForecastPoint extends Equatable {
  /// Local midnight for this forecast day.
  final DateTime date;

  /// Predicted value in cents.
  /// Signed for [ForecastTarget.balance]; non-negative magnitude for expense targets.
  final int predictedCents;

  /// 80% CI lower bound in cents. May be null if no CI is available.
  final int? lowerCents;

  /// 80% CI upper bound in cents. May be null if no CI is available.
  final int? upperCents;

  const ForecastPoint({
    required this.date,
    required this.predictedCents,
    this.lowerCents,
    this.upperCents,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'predicted_cents': predictedCents,
        if (lowerCents != null) 'lower_cents': lowerCents,
        if (upperCents != null) 'upper_cents': upperCents,
      };

  factory ForecastPoint.fromJson(Map<String, dynamic> json) => ForecastPoint(
        date: DateTime.parse(json['date'] as String),
        predictedCents: json['predicted_cents'] as int,
        lowerCents: json['lower_cents'] as int?,
        upperCents: json['upper_cents'] as int?,
      );

  @override
  List<Object?> get props => [date, predictedCents, lowerCents, upperCents];
}

/// A complete forecast produced by a [ForecastingService].
class Forecast extends Equatable {
  /// Unique identifier (UUID v4).
  final String id;

  final DateTime generatedAt;
  final ForecastTarget target;

  /// Non-null only when [target] == [ForecastTarget.expenseByCategory].
  final String? categoryId;

  /// Must be one of 7, 14, or 30.
  final int horizonDays;

  final String modelName;
  final String modelVersion;
  final List<ForecastPoint> points;

  const Forecast({
    required this.id,
    required this.generatedAt,
    required this.target,
    this.categoryId,
    required this.horizonDays,
    required this.modelName,
    required this.modelVersion,
    required this.points,
  });

  /// Creates a new [Forecast] with a freshly generated UUID and current timestamp.
  ///
  /// Throws [ArgumentError] if [horizonDays] is not in {7, 14, 30}.
  factory Forecast.create({
    required ForecastTarget target,
    String? categoryId,
    required int horizonDays,
    required String modelName,
    required String modelVersion,
    required List<ForecastPoint> points,
  }) {
    if (!const [7, 14, 30].contains(horizonDays)) {
      throw ArgumentError(
        'horizonDays must be 7, 14, or 30; got $horizonDays',
      );
    }
    return Forecast(
      id: const Uuid().v4(),
      generatedAt: DateTime.now(),
      target: target,
      categoryId: categoryId,
      horizonDays: horizonDays,
      modelName: modelName,
      modelVersion: modelVersion,
      points: points,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'generated_at': generatedAt.toIso8601String(),
        'target': target.name,
        'category_id': categoryId,
        'horizon_days': horizonDays,
        'model_name': modelName,
        'model_version': modelVersion,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory Forecast.fromJson(Map<String, dynamic> json) {
    final horizonDays = json['horizon_days'] as int;
    if (!const [7, 14, 30].contains(horizonDays)) {
      throw ArgumentError(
        'horizonDays must be 7, 14, or 30; got $horizonDays',
      );
    }
    return Forecast(
      id: json['id'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      target: ForecastTarget.values.byName(json['target'] as String),
      categoryId: json['category_id'] as String?,
      horizonDays: horizonDays,
      modelName: json['model_name'] as String,
      modelVersion: json['model_version'] as String,
      points: (json['points'] as List<dynamic>)
          .map((p) => ForecastPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        generatedAt,
        target,
        categoryId,
        horizonDays,
        modelName,
        modelVersion,
        points,
      ];
}
