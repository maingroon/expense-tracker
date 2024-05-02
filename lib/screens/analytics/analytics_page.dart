import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  String _buildPeriodText() {
    String text = DateFormat.MMMM().format(_selectedDate);
    text += ' ';
    text += DateFormat.y().format(_selectedDate);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
              left: 8,
              right: 8,
            ),
            child: Card(
              margin: const EdgeInsets.all(0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = Jiffy.parseFromDateTime(_selectedDate)
                            .subtract(months: 1)
                            .dateTime;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    _buildPeriodText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = Jiffy.parseFromDateTime(_selectedDate)
                            .add(months: 1)
                            .dateTime;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ),
          AnalyticsSummaryWidget(
            selectedDate: _selectedDate,
          ),
          AnalyticsChartWidget(
            selectedDate: _selectedDate,
          ),
        ],
      ),
    );
  }
}

class AnalyticsSummaryWidget extends StatelessWidget {
  const AnalyticsSummaryWidget({
    required this.selectedDate,
    super.key,
  });

  final DateTime selectedDate;

  Widget _buildSummaryItem({
    required String title,
    required int value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${value / 100}',
              style: TextStyle(
                fontSize: 24,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        left: 8,
        right: 8,
      ),
      child: Card(
        margin: const EdgeInsets.all(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryItem(
              title: 'Income',
              value: TransactionsService.getIncomeByDate(
                Jiffy.parseFromDateTime(selectedDate)
                    .startOf(Unit.month)
                    .dateTime,
                Jiffy.parseFromDateTime(selectedDate)
                    .endOf(Unit.month)
                    .dateTime,
              ),
              color: Colors.green,
            ),
            _buildSummaryItem(
              title: 'Expenses',
              value: TransactionsService.getExpenseByDate(
                Jiffy.parseFromDateTime(selectedDate)
                    .startOf(Unit.month)
                    .dateTime,
                Jiffy.parseFromDateTime(selectedDate)
                    .endOf(Unit.month)
                    .dateTime,
              ),
              color: Colors.red,
            ),
            _buildSummaryItem(
              title: 'Difference',
              value: TransactionsService.getBalanceByDate(
                Jiffy.parseFromDateTime(selectedDate)
                    .startOf(Unit.month)
                    .dateTime,
                Jiffy.parseFromDateTime(selectedDate)
                    .endOf(Unit.month)
                    .dateTime,
              ),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsChartWidget extends StatelessWidget {
  const AnalyticsChartWidget({
    required this.selectedDate,
    super.key,
  });

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final categoriesSum = TransactionsService.getSortedCateogriesSum(
      Jiffy.parseFromDateTime(selectedDate).startOf(Unit.month).dateTime,
      Jiffy.parseFromDateTime(selectedDate).endOf(Unit.month).dateTime,
    );
    return Expanded(
      child: ListView.builder(
        itemCount: categoriesSum.length,
        itemBuilder: (context, index) {
          final categorySum = categoriesSum[index];
          final category = categorySum.key;
          final sum = categorySum.value;
          return Padding(
            padding: const EdgeInsets.only(
              top: 8,
              left: 8,
              right: 8,
            ),
            child: Card(
              margin: const EdgeInsets.all(0),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        category.icon,
                        color: category.color,
                      ),
                    ),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '${sum / 100}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
