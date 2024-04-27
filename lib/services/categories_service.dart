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

  static void addCategory(Category transaction) {
    _categories.add(transaction);
  }

  static void removeCategory(Category transaction) {
    _categories.remove(transaction);
  }
}
