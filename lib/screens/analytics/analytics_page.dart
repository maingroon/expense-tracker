import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/models/forecast_request_model.dart';
import 'package:expense_tracker/screens/widgets/month_navigator.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/forecasting_exceptions.dart';
import 'package:expense_tracker/services/forecasting_service.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

const int _forecastHorizonDays = 30;
const int _topForecastCategories = 5;

String _formatCents(int cents) {
  final formatted = NumberFormat('#,##0.00').format(cents.abs() / 100);
  return cents < 0 ? '-$formatted' : formatted;
}

DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _selectedDate = _firstOfMonth(DateTime.now());

  int _monthIndex(DateTime d) => d.year * 12 + (d.month - 1);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedIdx = _monthIndex(_selectedDate);
    final currentIdx = _monthIndex(now);
    final isCurrentMonth = selectedIdx == currentIdx;
    final isNextMonth = selectedIdx == currentIdx + 1;
    final canGoForward = selectedIdx < currentIdx + 1;

    final monthStart =
        Jiffy.parseFromDateTime(_selectedDate).startOf(Unit.month).dateTime;
    final monthEnd =
        Jiffy.parseFromDateTime(_selectedDate).endOf(Unit.month).dateTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: MonthNavigator(
          date: _selectedDate,
          onPrev: () => setState(() {
            _selectedDate = Jiffy.parseFromDateTime(_selectedDate)
                .subtract(months: 1)
                .dateTime;
          }),
          onNext: canGoForward
              ? () => setState(() {
                    _selectedDate = Jiffy.parseFromDateTime(_selectedDate)
                        .add(months: 1)
                        .dateTime;
                  })
              : null,
        ),
      ),
      body: isNextMonth
          ? _ForecastMonthView(key: ValueKey(_selectedDate))
          : _RealMonthView(
              monthStart: monthStart,
              monthEnd: monthEnd,
              isCurrentMonth: isCurrentMonth,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Real-data view (past months + current month)
// ---------------------------------------------------------------------------

class _RealMonthView extends StatelessWidget {
  const _RealMonthView({
    required this.monthStart,
    required this.monthEnd,
    required this.isCurrentMonth,
  });

  final DateTime monthStart;
  final DateTime monthEnd;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _OverviewCard(
          monthStart: monthStart,
          monthEnd: monthEnd,
          isCurrentMonth: isCurrentMonth,
        ),
        _CategoryBreakdown(
          monthStart: monthStart,
          monthEnd: monthEnd,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.monthStart,
    required this.monthEnd,
    required this.isCurrentMonth,
  });

  final DateTime monthStart;
  final DateTime monthEnd;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final asOf = isCurrentMonth ? DateTime.now() : monthEnd;
    final balance = TransactionsService.getBalanceUpToDate(asOf);
    final balanceLabel =
        isCurrentMonth ? 'Current balance' : 'End-of-month balance';
    final balanceColor =
        balance >= 0 ? colorScheme.primary : colorScheme.error;

    final income = TransactionsService.getIncomeByDate(monthStart, monthEnd);
    final expense = TransactionsService.getExpenseByDate(monthStart, monthEnd);
    final net = income - expense;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _BalanceColumn(
                    label: balanceLabel,
                    cents: balance,
                    color: balanceColor,
                    asOf: asOf,
                  ),
                ),
                VerticalDivider(
                  color: theme.dividerColor,
                  thickness: 1,
                  width: 24,
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SummaryLine(
                        icon: Icons.arrow_upward,
                        label: 'Income',
                        cents: income,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _SummaryLine(
                        icon: Icons.arrow_downward,
                        label: 'Expenses',
                        cents: expense,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      _SummaryLine(
                        icon: net >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        label: 'Net',
                        cents: net,
                        color: net >= 0 ? Colors.blue : Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({
    required this.label,
    required this.cents,
    required this.color,
    required this.asOf,
  });

  final String label;
  final int cents;
  final Color color;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _formatCents(cents),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'as of ${DateFormat.yMMMd().format(asOf)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.cents,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int cents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          _formatCents(cents),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.monthStart,
    required this.monthEnd,
  });

  final DateTime monthStart;
  final DateTime monthEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = context.watch<ThemeProvider>().getIconsShadows();

    final allCategoriesSum = TransactionsService.getSortedCategoriesSum(
      monthStart,
      monthEnd,
    );
    final entries = allCategoriesSum.where((entry) {
      final category = CategoriesService.getCategoryById(entry.key);
      return category != null && category.enabled;
    }).toList();

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        child: Center(
          child: Text(
            'No transactions this month.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxAmount = entries.first.value;
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
          child: Text(
            'By category',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final entry in entries)
          _CategoryRow(
            categoryId: entry.key,
            cents: entry.value,
            maxCents: maxAmount,
            totalCents: total,
            shadows: shadows,
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.cents,
    required this.maxCents,
    required this.totalCents,
    required this.shadows,
  });

  final String categoryId;
  final int cents;
  final int maxCents;
  final int totalCents;
  final List<Shadow> shadows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = CategoriesService.getCategoryById(categoryId)!;
    final fraction = maxCents == 0 ? 0.0 : cents / maxCents;
    final share = totalCents == 0 ? 0.0 : cents / totalCents;
    final percentText = '${(share * 100).toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    category.icon,
                    color: category.color,
                    shadows: shadows,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatCents(cents),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(category.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    child: Text(
                      percentText,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Forecast view (next month only)
// ---------------------------------------------------------------------------

class _ForecastResult {
  _ForecastResult({
    required this.balanceForecast,
    required this.totalExpenseCents,
    required this.totalIncomeCents,
    required this.netCents,
    required this.categoryTotals,
  });

  final Forecast balanceForecast;
  final int totalExpenseCents;
  final int totalIncomeCents;
  final int netCents;
  final List<({Category category, int totalCents})> categoryTotals;
}

class _ForecastMonthView extends StatefulWidget {
  const _ForecastMonthView({super.key});

  @override
  State<_ForecastMonthView> createState() => _ForecastMonthViewState();
}

class _ForecastMonthViewState extends State<_ForecastMonthView> {
  late Future<_ForecastResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _runForecast();
  }

  Future<_ForecastResult> _runForecast() async {
    final service = context.read<ForecastingService>();
    final asOf = DateTime.now();

    final hasHistory = await service.hasEnoughHistory;
    if (!hasHistory) {
      final avail = await service.availableHistoryDays;
      throw InsufficientHistoryException(
        availableDays: avail,
        requiredDays: 1,
      );
    }

    final balanceForecast = await service.forecast(
      ForecastRequest(
        target: ForecastTarget.balance,
        horizonDays: _forecastHorizonDays,
        asOf: asOf,
      ),
    );

    final expenseForecast = await service.forecast(
      ForecastRequest(
        target: ForecastTarget.expenseTotal,
        horizonDays: _forecastHorizonDays,
        asOf: asOf,
      ),
    );
    final totalExpense = expenseForecast.points
        .fold<int>(0, (sum, p) => sum + p.predictedCents);

    final topCatIds = _topExpenseCategoryIds(_topForecastCategories);
    final categoryTotals = <({Category category, int totalCents})>[];
    for (final id in topCatIds) {
      final cat = CategoriesService.getCategoryById(id);
      if (cat == null) continue;
      try {
        final f = await service.forecast(
          ForecastRequest(
            target: ForecastTarget.expenseByCategory,
            categoryId: id,
            horizonDays: _forecastHorizonDays,
            asOf: asOf,
          ),
        );
        final total =
            f.points.fold<int>(0, (sum, p) => sum + p.predictedCents);
        if (total > 0) {
          categoryTotals.add((category: cat, totalCents: total));
        }
      } catch (_) {
        // Skip categories that fail (e.g. no history).
      }
    }
    categoryTotals.sort((a, b) => b.totalCents.compareTo(a.totalCents));

    final currentBalance = TransactionsService.getBalanceUpToDate(asOf);
    final balanceAtHorizon = balanceForecast.points.last.predictedCents;
    final netCents = balanceAtHorizon - currentBalance;
    final totalIncome = netCents + totalExpense;

    return _ForecastResult(
      balanceForecast: balanceForecast,
      totalExpenseCents: totalExpense,
      totalIncomeCents: totalIncome,
      netCents: netCents,
      categoryTotals: categoryTotals,
    );
  }

  List<String> _topExpenseCategoryIds(int n) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final sums = TransactionsService.getSortedCategoriesSum(from, now);
    final expenses = sums.where((entry) {
      final cat = CategoriesService.getCategoryById(entry.key);
      return cat != null &&
          cat.enabled &&
          cat.type == CategoryType.expense;
    }).toList();
    return expenses.take(n).map((e) => e.key).toList();
  }

  void _retry() {
    setState(() => _future = _runForecast());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ForecastResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ForecastLoading();
        }
        final error = snapshot.error;
        if (error is InsufficientHistoryException) {
          return _ForecastInsufficientHistory(
            availableDays: error.availableDays,
            requiredDays: error.requiredDays,
          );
        }
        if (error != null) {
          return _ForecastError(error: error, onRetry: _retry);
        }
        final result = snapshot.data!;
        return _ForecastLoaded(result: result);
      },
    );
  }
}

class _ForecastLoaded extends StatelessWidget {
  const _ForecastLoaded({required this.result});

  final _ForecastResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = context.watch<ThemeProvider>().getIconsShadows();
    final last = result.balanceForecast.points.last;

    final maxCat = result.categoryTotals.isEmpty
        ? 0
        : result.categoryTotals.first.totalCents;
    final totalCat = result.categoryTotals
        .fold<int>(0, (s, e) => s + e.totalCents);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  size: 18,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Forecast — based on the next $_forecastHorizonDays days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ForecastOverviewCard(
          point: last,
          totalIncomeCents: result.totalIncomeCents,
          totalExpenseCents: result.totalExpenseCents,
          netCents: result.netCents,
        ),
        if (result.categoryTotals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            child: Center(
              child: Text(
                'Not enough per-category history to forecast.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(
                top: 16, left: 16, right: 16, bottom: 4),
            child: Text(
              'Projected by category',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final entry in result.categoryTotals)
            _CategoryRow(
              categoryId: entry.category.id,
              cents: entry.totalCents,
              maxCents: maxCat,
              totalCents: totalCat,
              shadows: shadows,
            ),
        ],
      ],
    );
  }
}

class _ForecastOverviewCard extends StatelessWidget {
  const _ForecastOverviewCard({
    required this.point,
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.netCents,
  });

  final ForecastPoint point;
  final int totalIncomeCents;
  final int totalExpenseCents;
  final int netCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final balanceColor =
        point.predictedCents >= 0 ? colorScheme.primary : colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Projected balance',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatCents(point.predictedCents),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: balanceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (point.lowerCents != null &&
                          point.upperCents != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '80% CI: ${_formatCents(point.lowerCents!)} – '
                          '${_formatCents(point.upperCents!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'by ${DateFormat.yMMMd().format(point.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  color: theme.dividerColor,
                  thickness: 1,
                  width: 24,
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SummaryLine(
                        icon: Icons.arrow_upward,
                        label: 'Income',
                        cents: totalIncomeCents,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _SummaryLine(
                        icon: Icons.arrow_downward,
                        label: 'Expenses',
                        cents: totalExpenseCents,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      _SummaryLine(
                        icon: netCents >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        label: 'Net',
                        cents: netCents,
                        color:
                            netCents >= 0 ? Colors.blue : Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForecastLoading extends StatelessWidget {
  const _ForecastLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ForecastInsufficientHistory extends StatelessWidget {
  const _ForecastInsufficientHistory({
    required this.availableDays,
    required this.requiredDays,
  });

  final int availableDays;
  final int requiredDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysNeeded = requiredDays - availableDays;
    final String message;
    if (availableDays == 0) {
      message = 'Add your first transaction to unlock forecasts.';
    } else if (daysNeeded > 0) {
      message = 'Keep logging for $daysNeeded more '
          'day${daysNeeded == 1 ? '' : 's'} to unlock forecasts.';
    } else {
      message = 'Keep logging a little longer to unlock forecasts.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Not enough history',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ForecastError extends StatelessWidget {
  const _ForecastError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not build forecast',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
