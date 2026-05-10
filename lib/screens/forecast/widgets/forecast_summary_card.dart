import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/services/forecast_risk.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ForecastSummaryCard extends StatelessWidget {
  const ForecastSummaryCard({required this.forecast, super.key});

  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final last = forecast.points.last;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = forecast.target == ForecastTarget.balance
        ? 'Projected balance in ${forecast.horizonDays} days'
        : 'Projected expenses in ${forecast.horizonDays} days';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(
              _formatCents(last.predictedCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: last.predictedCents >= 0
                    ? colorScheme.primary
                    : colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (last.lowerCents != null && last.upperCents != null) ...[
              const SizedBox(height: 4),
              Text(
                '80% CI: ${_formatCents(last.lowerCents!)} – ${_formatCents(last.upperCents!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (forecast.target == ForecastTarget.balance) ...[
              const SizedBox(height: 4),
              Builder(builder: (_) {
                final risk = overdraftRisk(forecast);
                final pct = (risk.endOfHorizon * 100).round();
                final danger = risk.endOfHorizon >= 0.20;
                return Text(
                  'Risk of overdraft within ${forecast.horizonDays} days: $pct%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: danger ? colorScheme.error : colorScheme.outline,
                    fontWeight: danger ? FontWeight.w600 : null,
                  ),
                );
              }),
            ],
            const SizedBox(height: 4),
            Text(
              'by ${DateFormat('d MMM y').format(last.date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCents(int cents) {
    final value = cents / 100;
    final formatted = NumberFormat('#,##0.00').format(value.abs());
    return cents < 0 ? '-$formatted' : formatted;
  }
}
