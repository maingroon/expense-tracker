import 'package:expense_tracker/models/forecast_insight.dart';
import 'package:flutter/material.dart';

class InsightsPanel extends StatelessWidget {
  const InsightsPanel({required this.insights, super.key});

  final List<ForecastInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Text('Insights', style: theme.textTheme.titleSmall),
            ),
            ...insights.map((i) => _InsightTile(insight: i)),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});
  final ForecastInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (insight.severity) {
      InsightSeverity.danger => colors.error,
      InsightSeverity.warning => Colors.orange.shade700,
      InsightSeverity.positive => Colors.green.shade700,
      InsightSeverity.neutral => colors.outline,
    };
    return ListTile(
      dense: true,
      leading: Icon(insight.icon, color: color),
      title: Text(
        insight.title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: insight.detail == null ? null : Text(insight.detail!),
    );
  }
}
