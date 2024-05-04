import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/services/database_service.dart';

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

  static void removeCategory(Category category) {
    _categories.removeWhere((listCategory) {
      return listCategory.id == category.id;
    });
    _databaseService.deleteCategory(category);
  }

  static void reorderCategories(int oldIndex, int newIndex) {
    final Category oldIndexCategory = _categories[oldIndex];
    final Category newIndexCategory = _categories[newIndex];

    oldIndexCategory.position = newIndex;
    newIndexCategory.position = oldIndex;

    _categories.removeAt(oldIndex);
    _categories.insert(newIndex, oldIndexCategory);

    _databaseService.updateCategory(oldIndexCategory);
    _databaseService.updateCategory(newIndexCategory);
  }
}
