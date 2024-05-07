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

  static Category getCategoryById(String id) {
    return _categories.firstWhere((category) {
      return category.id == id;
    });
  }

  static void addCategory(Category category) {
    _categories.add(category);
    _databaseService.insertCategory(category);
  }

  static void updateCategory(Category category) {
    _databaseService.updateCategory(category);
  }

  static void updateAllCategoriesPositions() {
    for (int i = 0; i < _categories.length; i++) {
      final Category category = _categories[i];
      final int oldPosition = category.position;
      if (oldPosition != i) {
        category.position = i;
        _databaseService.updateCategory(category);
      }
    }
  }

  static void deleteCategory(Category category) {
    _categories.removeWhere((listCategory) {
      return listCategory.id == category.id;
    });
    TransactionsService.deleteTransactionsByCategoryId(category.id);
    _databaseService.deleteCategory(category);

    updateAllCategoriesPositions();
  }

  static void disableCategory(Category category) {
    category.enabled = false;
    _databaseService.updateCategory(category);

    updateAllCategoriesPositions();
  }

  static void reorderCategories(int oldIndex, int newIndex) {
    final Category oldIndexCategory = _categories[oldIndex];
    _categories.removeAt(oldIndex);
    _categories.insert(newIndex, oldIndexCategory);

    updateAllCategoriesPositions();
  }
}
