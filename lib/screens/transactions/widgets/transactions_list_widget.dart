import 'package:expense_tracker/screens/transactions/widgets/transaction_card_widget.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';

class TransactionsListWidget extends StatelessWidget {

  const TransactionsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = TransactionService.transactions;
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (ctx, index) {
        return TransactionCardWidget(transaction: transactions[index]);
      },
    );
  }
}