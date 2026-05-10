import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/categories/widgets/save_category_widget.dart';
import 'package:expense_tracker/screens/transactions/widgets/save_transaction_widget.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_draggable_gridview/flutter_draggable_gridview.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late CategoryPageEvent _pageEvent;
  late Icon _actionIcon;

  @override
  void initState() {
    super.initState();
    _pageEvent = _getInitialPageEvent();
    _actionIcon = Icon(_getInitialActionIcon());
  }

  List<Category> _allEnabledCategories() {
    return CategoriesService.categories.where((c) => c.enabled).toList();
  }

  List<Category> _categoriesOfType(CategoryType type) {
    return CategoriesService.categories
        .where((c) => c.enabled && c.type == type)
        .toList();
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
          onSave: (transaction) async {
            await TransactionsService.addTransaction(transaction);
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
          onDelete: (category) async {
            await CategoriesService.deleteCategory(category);
            if (mounted) {
              setState(() {});
              Navigator.of(context).pop();
            }
          },
          onArchive: (category) async {
            await CategoriesService.disableCategory(category);
            if (mounted) {
              setState(() {});
              Navigator.of(context).pop();
            }
          },
          onSave: (updatedCategory) async {
            category.name = updatedCategory.name;
            category.icon = updatedCategory.icon;
            category.color = updatedCategory.color;
            category.type = updatedCategory.type;
            await CategoriesService.updateCategory(category);
            if (mounted) {
              setState(() {});
              Navigator.of(context).pop();
            }
          },
          saveMode: CategorySaveMode.edit,
        );
      },
    );
  }

  void _onAddCategory(CategoryType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SaveCategoryWidget(
          category: Category.create(
            icon: Icons.category,
            color: Colors.grey,
            name: '',
            type: type,
            position: _allEnabledCategories().length,
          ),
          onDelete: (category) => {},
          onArchive: (category) {},
          onSave: (category) async {
            await CategoriesService.addCategory(category);
            if (mounted) {
              setState(() {});
              Navigator.of(context).pop();
            }
          },
          saveMode: CategorySaveMode.create,
        );
      },
    );
  }

  CategoryPageEvent _getInitialPageEvent() {
    if (_allEnabledCategories().isEmpty) {
      return CategoryPageEvent.editCategory;
    } else {
      return CategoryPageEvent.addTransaction;
    }
  }

  IconData _getInitialActionIcon() {
    if (_allEnabledCategories().isEmpty ||
        _pageEvent == CategoryPageEvent.editCategory) {
      return Icons.save;
    } else {
      return Icons.edit;
    }
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
              child: CircleAvatar(
                radius: 22,
                backgroundColor: category.color.withAlpha(180),
                child: Icon(
                  category.icon,
                  color: Colors.white,
                  size: 24,
                ),
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
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.withAlpha(180),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
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

  List<DraggableGridItem> _buildCategoriesWidgets(CategoryType type) {
    final categories = _categoriesOfType(type);
    final categoryWidgets = categories.map((category) {
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

    if (_pageEvent == CategoryPageEvent.editCategory) {
      categoryWidgets.add(
        DraggableGridItem(
          child: GestureDetector(
            onTap: () => _onAddCategory(type),
            child: _buildAddCategoryCardWidget(),
          ),
        ),
      );
    }

    return categoryWidgets;
  }

  Future<void> _onDragCompleteWithinTab(
    CategoryType type,
    int beforeIndex,
    int afterIndex,
  ) async {
    final tabCategories = _categoriesOfType(type);
    if (beforeIndex >= tabCategories.length ||
        afterIndex >= tabCategories.length) {
      // The trailing "Add" card is non-draggable, but guard anyway.
      return;
    }
    final movingCategory = tabCategories[beforeIndex];
    final targetCategory = tabCategories[afterIndex];
    final globalCategories = CategoriesService.categories;
    final globalOld =
        globalCategories.indexWhere((c) => c.id == movingCategory.id);
    final globalNew =
        globalCategories.indexWhere((c) => c.id == targetCategory.id);
    if (globalOld < 0 || globalNew < 0) return;
    await CategoriesService.reorderCategories(globalOld, globalNew);
    if (mounted) setState(() {});
  }

  Widget _buildGrid(CategoryType type) {
    return DraggableGridViewBuilder(
      isOnlyLongPress: false,
      padding: const EdgeInsets.all(5),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      dragCompletion: (list, beforeIndex, afterIndex) =>
          _onDragCompleteWithinTab(type, beforeIndex, afterIndex),
      dragPlaceHolder: (list, index) {
        return PlaceHolderWidget(
          child: Container(
            color: Colors.transparent,
          ),
        );
      },
      children: _buildCategoriesWidgets(type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  if (_allEnabledCategories().isEmpty ||
                      _pageEvent == CategoryPageEvent.addTransaction) {
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGrid(CategoryType.expense),
            _buildGrid(CategoryType.income),
          ],
        ),
      ),
    );
  }
}

enum CategoryPageEvent {
  addTransaction,
  editCategory,
}
