import 'dart:math' as math;

import 'package:expense_tracker/models/forecast_model.dart';

/// Pair of overdraft probabilities derived from a balance forecast's CI band.
class OverdraftRisk {
  /// P(balance at the final forecast day < 0).
  final double endOfHorizon;

  /// Marginal upper bound for P(balance dips below 0 on any day in the horizon).
  /// Computed as max_d Φ(−predicted_d / σ_d).
  final double anyDay;

  const OverdraftRisk({required this.endOfHorizon, required this.anyDay});
}

/// Standard normal CDF using the Abramowitz & Stegun 26.2.17 approximation.
/// Accurate to ~7e-8 across the real line — more than enough for risk display.
double normalCdf(double z) {
  if (z.isNaN) return double.nan;
  final sign = z < 0 ? -1.0 : 1.0;
  final x = z.abs() / math.sqrt2;

  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;

  final t = 1.0 / (1.0 + p * x);
  final y = 1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
          t *
          math.exp(-x * x);

  return 0.5 * (1.0 + sign * y);
}

/// Returns the probability that [balanceForecast]'s implied trajectory crosses
/// zero. Treats each forecast day as an independent Gaussian
/// `N(predicted_d, σ_d)` with σ_d recovered from the 80 % CI band.
///
/// If the forecast lacks CI information, every probability collapses to 0.
OverdraftRisk overdraftRisk(Forecast balanceForecast) {
  final points = balanceForecast.points;
  if (points.isEmpty) {
    return const OverdraftRisk(endOfHorizon: 0, anyDay: 0);
  }

  double endRisk = 0;
  double anyDayRisk = 0;
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final risk = _pBelow(p, 0);
    if (risk > anyDayRisk) anyDayRisk = risk;
    if (i == points.length - 1) endRisk = risk;
  }
  return OverdraftRisk(endOfHorizon: endRisk, anyDay: anyDayRisk);
}

/// Returns max_d P(forecast_d < [thresholdCents]) under the same Gaussian
/// approximation as [overdraftRisk]. Useful for arbitrary spending caps.
double thresholdBreachProbability(Forecast f, int thresholdCents) {
  if (f.points.isEmpty) return 0;
  double worst = 0;
  for (final p in f.points) {
    final r = _pBelow(p, thresholdCents);
    if (r > worst) worst = r;
  }
  return worst;
}

double _pBelow(ForecastPoint point, int threshold) {
  final lower = point.lowerCents;
  if (lower == null) return 0;
  // 80 % CI: lower = predicted − 1.28 σ  ⇒  σ = (predicted − lower) / 1.28.
  final sigma = (point.predictedCents - lower) / 1.28;
  if (sigma <= 0) {
    return point.predictedCents < threshold ? 1.0 : 0.0;
  }
  final z = (threshold - point.predictedCents) / sigma;
  return normalCdf(z);
}
