import 'package:expense_tracker/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionCardWidget extends StatelessWidget {
  final Transaction _transaction;

  const TransactionCardWidget({
    Key? key,
    required Transaction transaction,
  })  : _transaction = transaction,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                child: Icon(_transaction.category.icon),
              ),
            ),
          ),
          title: Text(
            _transaction.note,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            DateFormat.yMMMd().format(_transaction.date),
          ),
          trailing: Text(
            '\$${_transaction.amount / 100}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )),
    );
  }
}
