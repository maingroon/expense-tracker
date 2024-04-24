import 'package:expense_tracker/models/category_model.dart';
import 'package:flutter/material.dart';

class CategoriesService {
  CategoriesService._();

  static final List<Category> _categories = [
    Category.create(
      icon: Icons.payments,
      color: Colors.green,
      name: 'Aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
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

  static List<Category> get categories => _categories;

  static void addCategory(Category transaction) {
    _categories.add(transaction);
  }

  static void removeCategory(Category transaction) {
    _categories.remove(transaction);
  }
}
