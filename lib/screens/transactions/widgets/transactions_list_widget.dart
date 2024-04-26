import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/transaction_card_widget.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';

class TransactionsListWidget extends StatefulWidget {
  const TransactionsListWidget({super.key});

  @override
  State<TransactionsListWidget> createState() => _TransactionsListWidgetState();
}

class _TransactionsListWidgetState extends State<TransactionsListWidget> {
  void _onRemoveTransaction(Transaction transaction) {
    setState(() {
      TransactionsService.removeTransaction(transaction);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactions = TransactionsService.transactions;
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
