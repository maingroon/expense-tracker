import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';

class TransactionsService {
  TransactionsService._();

  static final List<Transaction> _transactions = [];

  static List<Transaction> get transactions => _transactions;

  static void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
  }

  static void removeTransaction(Transaction transaction) {
    _transactions.remove(transaction);
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
          return transaction.category.type == CategoryType.income;
        })
        .map((transaction) => transaction.amount)
        .fold(0, (a, b) => a + b);
  }

  static int getExpenseByDate(DateTime fromDate, DateTime toDate) {
    return getTransactionsByDate(fromDate, toDate)
        .where((transaction) {
          return transaction.category.type == CategoryType.expense;
        })
        .map((transaction) => transaction.amount)
        .fold(0, (a, b) => a + b);
  }

  static int getBalanceByDate(DateTime fromDate, DateTime toDate) {
    return getIncomeByDate(fromDate, toDate) -
        getExpenseByDate(fromDate, toDate);
  }

  static List<MapEntry<Category, int>> getSortedCateogriesSum(
      DateTime fromDate, DateTime toDate) {
    Map<Category, int> categoriesSum = {};
    getTransactionsByDate(fromDate, toDate).forEach((transaction) {
      if (categoriesSum.containsKey(transaction.category)) {
        categoriesSum[transaction.category] =
            categoriesSum[transaction.category]! + transaction.amount;
      } else {
        categoriesSum[transaction.category] = transaction.amount;
      }
    });
    return categoriesSum.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}
