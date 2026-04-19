import 'package:collection/collection.dart';
import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/transactions_service.dart';

class CategoriesService {
  CategoriesService._();

  static final DatabaseService _databaseService = DatabaseService();

  static List<Category> _categories = [];

  static Future<void> init() async {
    _categories = await _databaseService.getAllCategories();
  }

  static List<Category> get categories => _categories;

  static Category? getCategoryById(String id) {
    return _categories.firstWhereOrNull((category) => category.id == id);
  }

  static Future<void> addCategory(Category category) async {
    await _databaseService.insertCategory(category);
    _categories.add(category);
  }

  static Future<void> updateCategory(Category category) async {
    await _databaseService.updateCategory(category);
  }

  static Future<void> updateAllCategoriesPositions() async {
    for (int i = 0; i < _categories.length; i++) {
      final Category category = _categories[i];
      final int oldPosition = category.position;
      if (oldPosition != i) {
        category.position = i;
        await _databaseService.updateCategory(category);
      }
    }
  }

  static Future<void> deleteCategory(Category category) async {
    await TransactionsService.deleteTransactionsByCategoryId(category.id);
    await _databaseService.deleteCategory(category);
    _categories.removeWhere((listCategory) => listCategory.id == category.id);
    await updateAllCategoriesPositions();
  }

  static Future<void> disableCategory(Category category) async {
    await _databaseService.updateCategory(category..enabled = false);
    await updateAllCategoriesPositions();
  }

  static Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final Category oldIndexCategory = _categories[oldIndex];
    _categories.removeAt(oldIndex);
    _categories.insert(newIndex, oldIndexCategory);
    await updateAllCategoriesPositions();
  }
}
