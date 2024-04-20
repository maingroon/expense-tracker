import 'package:expense_tracker/screens/transactions/widgets/transactions_list_widget.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: const TransactionsListWidget(),
    );
  }
}
