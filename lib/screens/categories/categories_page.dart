import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final List<Category> _categories = [
    Category.create(
      icon: Icons.payments,
      color: Colors.green,
      name: 'Salary',
      type: CategoryType.income,
    ),
    Category.create(
      icon: Icons.monetization_on,
      color: Colors.yellow,
      name: 'Bonus',
      type: CategoryType.income,
    ),
    Category.create(
      icon: Icons.account_balance,
      color: Colors.red,
      name: 'Actives',
      type: CategoryType.income,
    ),
  ];

  void _addTransaction(Transaction transaction) {
    TransactionService.addTransaction(transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () {
              print('edit');
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(5),
        children: _categories.map((category) {
          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: false,
                builder: (ctx) {
                  return SaveTransactionWidget(
                    transaction: Transaction.create(
                      amount: 0,
                      category: category,
                      date: DateTime.now(),
                      note: '',
                    ),
                    onSave: _addTransaction,
                  );
                },
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 30,
                        shadows: const [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.grey,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
