import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/database_service.dart';

class TransactionsService {
  TransactionsService._();

  static final DatabaseService _databaseService = DatabaseService();

  static List<Transaction> _transactions = [];

  static Future<void> init() async {
    _transactions = await _databaseService.getAllTransactions();
  }

  static List<Transaction> get transactions => _transactions;

  static Future<void> addTransaction(Transaction transaction) async {
    await _databaseService.insertTransaction(transaction);
    _transactions.add(transaction);
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    await _databaseService.updateTransaction(transaction);
  }

  static Future<void> deleteTransaction(Transaction transaction) async {
    await _databaseService.deleteTransaction(transaction);
    _transactions.removeWhere((t) => t.id == transaction.id);
  }

  static Future<void> deleteTransactionsByCategoryId(String categoryId) async {
    await _databaseService.deleteTransactionsByCategoryId(categoryId);
    _transactions.removeWhere((t) => t.categoryId == categoryId);
  }

  static List<Transaction> getTransactionsByDate(
      DateTime fromDate, DateTime toDate) {
    return _transactions.where((transaction) {
      return transaction.date.millisecondsSinceEpoch >=
              fromDate.millisecondsSinceEpoch &&
          transaction.date.millisecondsSinceEpoch <=
              toDate.millisecondsSinceEpoch;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static int getIncomeByDate(DateTime fromDate, DateTime toDate) {
    return getTransactionsByDate(fromDate, toDate)
        .where((transaction) {
          final category =
              CategoriesService.getCategoryById(transaction.categoryId);
          return category != null && category.type == CategoryType.income;
        })
        .map((transaction) => transaction.amount)
        .fold(0, (a, b) => a + b);
  }

  static int getExpenseByDate(DateTime fromDate, DateTime toDate) {
    return getTransactionsByDate(fromDate, toDate)
        .where((transaction) {
          final category =
              CategoriesService.getCategoryById(transaction.categoryId);
          return category != null && category.type == CategoryType.expense;
        })
        .map((transaction) => transaction.amount)
        .fold(0, (a, b) => a + b);
  }

  static int getBalanceByDate(DateTime fromDate, DateTime toDate) {
    return getIncomeByDate(fromDate, toDate) -
        getExpenseByDate(fromDate, toDate);
  }

  static List<MapEntry<String, int>> getSortedCategoriesSum(
      DateTime fromDate, DateTime toDate) {
    Map<String, int> categoriesSum = {};
    getTransactionsByDate(fromDate, toDate).forEach((transaction) {
      if (categoriesSum.containsKey(transaction.categoryId)) {
        categoriesSum[transaction.categoryId] =
            categoriesSum[transaction.categoryId]! + transaction.amount;
      } else {
        categoriesSum[transaction.categoryId] = transaction.amount;
      }
    });
    return categoriesSum.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}
