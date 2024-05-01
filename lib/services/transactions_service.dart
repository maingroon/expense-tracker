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
}
