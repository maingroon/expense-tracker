import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  CategoryPageEvent _pageEvent = CategoryPageEvent.addTransaction;
  Icon _actionIcon = const Icon(Icons.edit);

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

  List<Category> _getCategories() {
    return _categories;
  }

  void _addTransaction(Transaction transaction) {
    TransactionService.addTransaction(transaction);
  }

  void _onAddTransaction(Category category) {
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
  }

  void _onEditCategory(Category category) {
    print('Edit category: ${category.name}');
  }

  Card _buildCategoryCardWidget(Category category) {
    return Card(
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
    );
  }

  Card _buildAddCategoryCardWidget() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(
                Icons.add,
                color: Colors.grey,
                size: 30,
                shadows: [
                  Shadow(
                    blurRadius: 5,
                    color: Colors.grey,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                'Add category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoriesWidgets() {
    List<Widget> categoryWidgets = _getCategories().map((category) {
      return GestureDetector(
        onTap: () {
          if (_pageEvent == CategoryPageEvent.addTransaction) {
            _onAddTransaction(category);
          } else {
            _onEditCategory(category);
          }
        },
        child: _buildCategoryCardWidget(category),
      );
    }).toList();
    if (_pageEvent == CategoryPageEvent.editCategory) {
      categoryWidgets.add(
        GestureDetector(
          onTap: () {
            print('Add category');
          },
          child: _buildAddCategoryCardWidget(),
        ),
      );
    }
    return categoryWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_pageEvent == CategoryPageEvent.addTransaction) {
                  _pageEvent = CategoryPageEvent.editCategory;
                  _actionIcon = const Icon(Icons.save);
                } else {
                  _pageEvent = CategoryPageEvent.addTransaction;
                  _actionIcon = const Icon(Icons.edit);
                }
              });
            },
            icon: _actionIcon,
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(5),
        children: _buildCategoriesWidgets(),
      ),
    );
  }
}

enum CategoryPageEvent {
  addTransaction,
  editCategory,
}
