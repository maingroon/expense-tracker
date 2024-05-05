import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/categories/widgets/save_category_widget.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_draggable_gridview/flutter_draggable_gridview.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  CategoryPageEvent _pageEvent = CategoryPageEvent.addTransaction;
  Icon _actionIcon = const Icon(Icons.edit);

  List<Category> _getCategories() {
    return CategoriesService.categories;
  }

  void _onAddTransaction(Category category) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SaveTransactionWidget(
          transaction: Transaction.create(
            categoryId: category.id,
            amount: 0,
            date: DateTime.now(),
            note: '',
          ),
          onSave: (transaction) {
            TransactionsService.addTransaction(transaction);
          },
        );
      },
    );
  }

  void _onSaveCategory(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SaveCategoryWidget(
          category: category,
          onDelete: (category) {
            setState(() {
              CategoriesService.removeCategory(category);
            });
            Navigator.of(context).pop();
          },
          onSave: (updatedCategory) {
            setState(() {
              category.name = updatedCategory.name;
              category.icon = updatedCategory.icon;
              category.color = updatedCategory.color;
              category.type = updatedCategory.type;
            });
            CategoriesService.updateCategory(category);
            Navigator.of(context).pop();
          },
          saveMode: CategorySaveMode.edit,
        );
      },
    );
  }

  void _onAddCategory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SaveCategoryWidget(
          category: Category.create(
            icon: Icons.category,
            color: Colors.grey,
            name: '',
            type: CategoryType.expense,
            position: _getCategories().length,
          ),
          onDelete: (category) => {},
          onSave: (category) {
            setState(() {
              CategoriesService.addCategory(category);
            });
            Navigator.of(context).pop();
          },
          saveMode: CategorySaveMode.create,
        );
      },
    );
  }

  Card _buildCategoryCardWidget(Category category) {
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
          minHeight: 100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(
                category.icon,
                color: category.color,
                size: 30,
                shadows: ThemeProvider().getIconsShadows(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(
                Icons.add,
                color: Colors.grey,
                size: 30,
                shadows: ThemeProvider().getIconsShadows(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'Add',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  List<DraggableGridItem> _buildCategoriesWidgets() {
    List<DraggableGridItem> categoryWidgets = _getCategories().map((category) {
      return DraggableGridItem(
        isDraggable: _pageEvent == CategoryPageEvent.editCategory,
        child: GestureDetector(
          onTap: () {
            if (_pageEvent == CategoryPageEvent.addTransaction) {
              _onAddTransaction(category);
            } else {
              _onSaveCategory(category);
            }
          },
          child: _buildCategoryCardWidget(category),
        ),
      );
    }).toList();

    if (categoryWidgets.isEmpty &&
        _pageEvent == CategoryPageEvent.addTransaction) {
      setState(() {
        _pageEvent = CategoryPageEvent.editCategory;
        _actionIcon = const Icon(Icons.save);
      });
    }

    if (_pageEvent == CategoryPageEvent.editCategory) {
      categoryWidgets.add(
        DraggableGridItem(
          child: GestureDetector(
            onTap: _onAddCategory,
            child: _buildAddCategoryCardWidget(),
          ),
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
                if (_pageEvent == CategoryPageEvent.addTransaction ||
                    _getCategories().isEmpty) {
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
      body: DraggableGridViewBuilder(
        isOnlyLongPress: false,
        padding: const EdgeInsets.all(5),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        dragCompletion: (list, beforeIndex, afterIndex) {
          setState(() {
            CategoriesService.reorderCategories(beforeIndex, afterIndex);
          });
        },
        dragPlaceHolder: (list, index) {
          return PlaceHolderWidget(
            child: Container(
              color: Colors.transparent,
            ),
          );
        },
        children: _buildCategoriesWidgets(),
      ),
    );
  }
}

enum CategoryPageEvent {
  addTransaction,
  editCategory,
}
