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

  /// 30-day total for this category as a non-negative magnitude (expense or
  /// income, depending on `category.type`). When `null`, no status chip is
  /// rendered.
  final int? baselineCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCents =
        forecast.points.fold(0, (sum, p) => sum + p.predictedCents);
    final formatted = NumberFormat('#,##0.00').format(totalCents / 100);
    final chip = _statusChip(context, totalCents);
    final isIncome = category.type == CategoryType.income;
    final subtitle = isIncome
        ? '${forecast.horizonDays}-day projected income'
        : '${forecast.horizonDays}-day projected spend';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: CircleAvatar(
            backgroundColor: category.color.withAlpha(180),
            child: Icon(category.icon, color: Colors.white, size: 20),
          ),
          title: Text(category.name),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
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
        ),
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

  /// For expense categories, "Over" is bad (orange) and "Under" is good
  /// (green). Income flips the polarity: earning more than baseline is good.
  (String, Color, Color) _classify(BuildContext context, double ratio) {
    final isIncome = category.type == CategoryType.income;
    if (ratio >= kInsightOverRatio) {
      return isIncome
          ? ('Above', Colors.green.shade100, Colors.green.shade900)
          : ('Over', Colors.orange.shade100, Colors.orange.shade900);
    }
    if (ratio <= kInsightUnderRatio) {
      return isIncome
          ? ('Below', Colors.orange.shade100, Colors.orange.shade900)
          : ('Under', Colors.green.shade100, Colors.green.shade900);
    }
    final scheme = Theme.of(context).colorScheme;
    return ('On track', scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
  }
}
