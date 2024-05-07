import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/theme_provider.dart';
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
        title: const Text('Transactions'),
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
          TransactionsListWidget(
            fromDate: Jiffy.parseFromDateTime(_selectedDate)
                .startOf(Unit.month)
                .dateTime,
            toDate: Jiffy.parseFromDateTime(_selectedDate)
                .endOf(Unit.month)
                .dateTime,
          ),
        ],
      ),
    );
  }
}

class TransactionsListWidget extends StatefulWidget {
  const TransactionsListWidget({
    required this.fromDate,
    required this.toDate,
    super.key,
  });

  final DateTime fromDate;
  final DateTime toDate;

  @override
  State<TransactionsListWidget> createState() => _TransactionsListWidgetState();
}

class _TransactionsListWidgetState extends State<TransactionsListWidget> {
  void _onRemoveTransaction(Transaction transaction) {
    setState(() {
      TransactionsService.deleteTransaction(transaction);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactions = TransactionsService.getTransactionsByDate(
      widget.fromDate,
      widget.toDate,
    );
    return Expanded(
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (ctx, index) {
          return TransactionCardWidget(
            transaction: transactions[index],
            onRemove: _onRemoveTransaction,
          );
        },
      ),
    );
  }
}

class TransactionCardWidget extends StatefulWidget {
  final Transaction _transaction;
  final void Function(Transaction transaction) _onRemove;

  const TransactionCardWidget({
    Key? key,
    required Transaction transaction,
    required void Function(Transaction transaction) onRemove,
  })  : _transaction = transaction,
        _onRemove = onRemove,
        super(key: key);

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
          onSave: (editedTransaction) {
            setState(() {
              widget._transaction.categoryId = editedTransaction.categoryId;
              widget._transaction.amount = editedTransaction.amount;
              widget._transaction.date = editedTransaction.date;
              widget._transaction.note = editedTransaction.note;
            });
            TransactionsService.updateTransaction(widget._transaction);
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
          DateFormat.yMMMd().format(widget._transaction.date),
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
    final category =
        CategoriesService.getCategoryById(widget._transaction.categoryId);
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
            color: Theme.of(context).colorScheme.error.withOpacity(0.75),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      shadows: ThemeProvider().getIconsShadows(),
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
