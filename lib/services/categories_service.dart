import 'package:expense_tracker/models/category_model.dart';
import 'package:flutter/material.dart';

class CategoriesService {
  CategoriesService._();

  static final List<Category> _categories = [
    Category.create(
      icon: Icons.payments,
      color: Colors.green,
      name: 'Salary',
      type: CategoryType.income,
    ),
    Category.create(
      icon: Icons.home,
      color: Colors.blue,
      name: 'House',
      type: CategoryType.expense,
    ),
    Category.create(
      icon: Icons.shopping_cart,
      color: Colors.blueGrey,
      name: 'Food',
      type: CategoryType.expense,
    ),
  ];

  static List<Category> get categories => _categories;

  static void addCategory(Category category) {
    _categories.add(category);
  }

  static void removeCategory(Category category) {
    _categories.removeWhere((listCategory) => listCategory.id == category.id);
  }

  static void reorderCategories(int oldIndex, int newIndex) {
    final Category category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);
  }
}
