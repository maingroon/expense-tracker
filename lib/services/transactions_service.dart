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

  static void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _databaseService.insertTransaction(transaction);
  }

  static void updateTransaction(Transaction transaction) {
    _databaseService.updateTransaction(transaction);
  }

  static void removeTransaction(Transaction transaction) {
    _transactions.removeWhere((listTransaction) {
      return listTransaction.id == transaction.id;
    });
    _databaseService.deleteTransaction(transaction);
  }

  static List<Transaction> getTransactionsByDate(
      DateTime fromDate, DateTime toDate) {
    return _transactions.where((transaction) {
      return transaction.date.isAfter(fromDate) &&
          transaction.date.isBefore(toDate);
    }).toList();
  }

  static int getIncomeByDate(DateTime fromDate, DateTime toDate) {
    return getTransactionsByDate(fromDate, toDate)
        .where((transaction) {
          final category =
              CategoriesService.getCategoryById(transaction.categoryId);
          return category.type == CategoryType.income;
        })
        .map((transaction) => transaction.amount)
        .fold(0, (a, b) => a + b);
  }

  static int getExpenseByDate(DateTime fromDate, DateTime toDate) {
    return getTransactionsByDate(fromDate, toDate)
        .where((transaction) {
          final category =
              CategoriesService.getCategoryById(transaction.categoryId);
          return category.type == CategoryType.expense;
        })
        .map((transaction) => transaction.amount)
        .fold(0, (a, b) => a + b);
  }

  static int getBalanceByDate(DateTime fromDate, DateTime toDate) {
    return getIncomeByDate(fromDate, toDate) -
        getExpenseByDate(fromDate, toDate);
  }

  static List<MapEntry<String, int>> getSortedCateogriesSum(
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
