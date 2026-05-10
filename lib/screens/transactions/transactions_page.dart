import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:expense_tracker/screens/widgets/month_navigator.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Set<String> _selectedCategoryIds = <String>{};

  int _monthIndex(DateTime d) => d.year * 12 + (d.month - 1);

  Future<void> _openFilterDialog() async {
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => _CategoryFilterDialog(
        initialSelection: _selectedCategoryIds,
      ),
    );
    if (picked != null) {
      setState(() => _selectedCategoryIds = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canGoForward = _monthIndex(_selectedDate) < _monthIndex(now);
    final filterActive = _selectedCategoryIds.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Filter by category',
            onPressed: _openFilterDialog,
            icon: Icon(
              filterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
          ),
        ],
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
      body: TransactionsListWidget(
        fromDate: Jiffy.parseFromDateTime(_selectedDate)
            .startOf(Unit.month)
            .dateTime,
        toDate: Jiffy.parseFromDateTime(_selectedDate)
            .endOf(Unit.month)
            .dateTime,
        selectedCategoryIds: _selectedCategoryIds,
      ),
    );
  }
}

class _CategoryFilterDialog extends StatefulWidget {
  const _CategoryFilterDialog({required this.initialSelection});

  final Set<String> initialSelection;

  @override
  State<_CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<_CategoryFilterDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelection};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = CategoriesService.categories.where((c) => c.enabled).toList();
    final expense =
        all.where((c) => c.type == CategoryType.expense).toList();
    final income = all.where((c) => c.type == CategoryType.income).toList();

    Widget tile(Category c) {
      return CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        value: _selected.contains(c.id),
        onChanged: (v) {
          setState(() {
            if (v == true) {
              _selected.add(c.id);
            } else {
              _selected.remove(c.id);
            }
          });
        },
        secondary: CircleAvatar(
          radius: 16,
          backgroundColor: c.color.withAlpha(180),
          child: Icon(c.icon, color: Colors.white, size: 18),
        ),
        title: Text(c.name),
      );
    }

    Widget header(String label) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Filter by category'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            if (expense.isNotEmpty) ...[
              header('Expenses'),
              ...expense.map(tile),
            ],
            if (income.isNotEmpty) ...[
              header('Income'),
              ...income.map(tile),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class TransactionsListWidget extends StatefulWidget {
  const TransactionsListWidget({
    required this.fromDate,
    required this.toDate,
    this.selectedCategoryIds = const <String>{},
    super.key,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final Set<String> selectedCategoryIds;

  @override
  State<TransactionsListWidget> createState() => _TransactionsListWidgetState();
}

class _TransactionsListWidgetState extends State<TransactionsListWidget> {
  void _onRemoveTransaction(Transaction transaction) async {
    await TransactionsService.deleteTransaction(transaction);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedCategoryIds;
    final transactions = TransactionsService.getTransactionsByDate(
      widget.fromDate,
      widget.toDate,
    ).where((t) => selected.isEmpty || selected.contains(t.categoryId)).toList();
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (ctx, index) {
        return TransactionCardWidget(
          transaction: transactions[index],
          onRemove: _onRemoveTransaction,
        );
      },
    );
  }
}

class TransactionCardWidget extends StatefulWidget {
  final Transaction _transaction;
  final void Function(Transaction transaction) _onRemove;

  const TransactionCardWidget({
    super.key,
    required Transaction transaction,
    required void Function(Transaction transaction) onRemove,
  })  : _transaction = transaction,
        _onRemove = onRemove;

  @override
  State<TransactionCardWidget> createState() => _TransactionCardWidgetState();
}

class _TransactionCardWidgetState extends State<TransactionCardWidget> {
  void _onEditTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        return SaveTransactionWidget(
          transaction: widget._transaction,
          onSave: (editedTransaction) async {
            widget._transaction.categoryId = editedTransaction.categoryId;
            widget._transaction.amount = editedTransaction.amount;
            widget._transaction.date = editedTransaction.date;
            widget._transaction.note = editedTransaction.note;
            await TransactionsService.updateTransaction(widget._transaction);
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  Widget _buildSubtitle() {
    List<Widget> children = [];
    if (widget._transaction.note.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(
            top: 4,
            left: 8,
            right: 8,
          ),
          child: Text(widget._transaction.note),
        ),
      );
    }
    children.add(
      Padding(
        padding: const EdgeInsets.only(
          top: 4,
          left: 8,
          right: 8,
          bottom: 8,
        ),
        child: Text(
          DateFormat('d MMM y').format(widget._transaction.date),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Category? category =
        CategoriesService.getCategoryById(widget._transaction.categoryId);

    if (category == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        left: 8,
        right: 8,
      ),
      child: Card(
        margin: const EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
        child: Dismissible(
          key: ValueKey(widget._transaction.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            widget._onRemove(widget._transaction);
          },
          confirmDismiss: (direction) async => await showDialog(
            context: context,
            builder: (ctx) {
              return const TransactionConfirmationDialogWidget();
            },
          ),
          background: Card(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.75),
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              alignment: Alignment.centerRight,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ),
          child: ListTile(
            onTap: _onEditTransaction,
            title: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: category.color.withAlpha(180),
                      child: Icon(
                        category.icon,
                        color: Colors.white,
                        size: 18,
                      ),
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
            ),
            subtitle: _buildSubtitle(),
            trailing: Text(
              '${widget._transaction.amount / 100}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionConfirmationDialogWidget extends StatelessWidget {
  const TransactionConfirmationDialogWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Are you sure?'),
      content: const Text(
        'Do you want to remove the transaction?',
        style: TextStyle(
          fontSize: 15,
        ),
      ),
      contentPadding: const EdgeInsets.all(22),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Yes'),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}
