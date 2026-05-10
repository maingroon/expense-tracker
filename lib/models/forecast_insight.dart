import 'package:flutter/material.dart';

/// Visual / semantic weight of a [ForecastInsight].
/// Ordering is meaningful: items with higher severity appear first.
enum InsightSeverity { neutral, positive, warning, danger }

/// A single line shown in the Forecast tab's "Insights" panel.
class ForecastInsight {
  final InsightSeverity severity;

  /// Short headline (~6 words). Always shown.
  final String title;

  /// Optional supporting line shown beneath the title.
  final String? detail;

  final IconData icon;

  const ForecastInsight({
    required this.severity,
    required this.title,
    this.icon = Icons.info_outline,
    this.detail,
  });
}
