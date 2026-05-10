import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/services/forecast_insights.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryForecastTile extends StatelessWidget {
  const CategoryForecastTile({
    required this.category,
    required this.forecast,
    this.baselineCents,
    super.key,
  });

  final Category category;
  final Forecast forecast;

  /// 30-day expense total for this category as a non-negative magnitude.
  /// When `null`, no status chip is rendered.
  final int? baselineCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCents =
        forecast.points.fold(0, (sum, p) => sum + p.predictedCents);
    final formatted = NumberFormat('#,##0.00').format(totalCents / 100);
    final chip = _statusChip(context, totalCents);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category.color.withAlpha(180),
        child: Icon(category.icon, color: Colors.white, size: 20),
      ),
      title: Text(category.name),
      subtitle: Text(
        '${forecast.horizonDays}-day projected spend',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatted,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (chip != null) ...[
            const SizedBox(height: 4),
            chip,
          ],
        ],
      ),
    );
  }

  Widget? _statusChip(BuildContext context, int projectedCents) {
    final baseline = baselineCents;
    if (baseline == null || baseline <= 0) return null;
    final scaled = baseline * forecast.horizonDays / 30;
    if (scaled <= 0) return null;
    final ratio = projectedCents / scaled;

    final (label, bg, fg) = _classify(context, ratio);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  (String, Color, Color) _classify(BuildContext context, double ratio) {
    if (ratio >= kInsightOverRatio) {
      return ('Over', Colors.orange.shade100, Colors.orange.shade900);
    }
    if (ratio <= kInsightUnderRatio) {
      return ('Under', Colors.green.shade100, Colors.green.shade900);
    }
    final scheme = Theme.of(context).colorScheme;
    return ('On track', scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
  }
}
