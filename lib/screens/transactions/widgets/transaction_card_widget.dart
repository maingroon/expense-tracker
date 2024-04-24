import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionCardWidget extends StatefulWidget {
  final Transaction _transaction;

  const TransactionCardWidget({
    Key? key,
    required Transaction transaction,
  })  : _transaction = transaction,
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
    return Card(
      child: ListTile(
        onTap: _onEditTransaction,
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: widget._transaction.category.color.withOpacity(0.1),
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
    );
  }
}
