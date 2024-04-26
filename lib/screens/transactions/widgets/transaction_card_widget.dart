import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
              widget._transaction.amount = editedTransaction.amount;
              widget._transaction.category = editedTransaction.category;
              widget._transaction.date = editedTransaction.date;
              widget._transaction.note = editedTransaction.note;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        margin: const EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
        child: Dismissible(
          key: ValueKey(widget._transaction.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => {
            widget._onRemove(widget._transaction),
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
            leading: CircleAvatar(
              radius: 30,
              backgroundColor:
                  widget._transaction.category.color.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  child: Icon(
                    widget._transaction.category.icon,
                    color: widget._transaction.category.color,
                  ),
                ),
              ),
            ),
            title: Text(
              widget._transaction.note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              DateFormat.yMMMd().format(widget._transaction.date),
            ),
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
      content: const Text('Do you want to remove the transaction?',
          style: TextStyle(
            fontSize: 15,
          )),
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
