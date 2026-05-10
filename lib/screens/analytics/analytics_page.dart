import 'package:expense_tracker/screens/widgets/month_navigator.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

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
    final canGoForward = selectedIdx < currentIdx;

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
      body: ListView(
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
      ),
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
          'as of ${DateFormat('d MMM y').format(asOf)}',
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
  });

  final String categoryId;
  final int cents;
  final int maxCents;
  final int totalCents;

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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: category.color.withAlpha(180),
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 18,
                    ),
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
