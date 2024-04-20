import 'package:expense_tracker/models/transaction_model.dart';

class TransactionService {
  TransactionService._();

  static final List<Transaction> _transactions = [];

  static List<Transaction> get transactions => _transactions;

  static void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
  }

  static void removeTransaction(Transaction transaction) {
    _transactions.remove(transaction);
  }
}