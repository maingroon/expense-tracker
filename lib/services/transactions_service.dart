import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';

/// Transactions are kept in `_transactions` sorted ascending by date so that
/// date-range queries can binary-search the bounds and category aggregations
/// can iterate the slice directly without re-sorting on every UI build.
class TransactionsService {
  TransactionsService._();

  static final DatabaseService _databaseService = DatabaseService();

  static List<Transaction> _transactions = [];

  static final _TransactionsChangeNotifier _changes =
      _TransactionsChangeNotifier();

  /// Fires whenever the transaction set changes (add/update/delete). Listeners
  /// are responsible for invalidating any derived/cached state (e.g. forecasts).
  static Listenable get changes => _changes;

  static Future<void> init() async {
    _transactions = await _databaseService.getAllTransactions();
    _transactions.sort((a, b) => a.date.compareTo(b.date));
  }

  static List<Transaction> get transactions => _transactions;

  static Future<void> addTransaction(Transaction transaction) async {
    await _databaseService.insertTransaction(transaction);
    _insertSorted(transaction);
    _changes.notify();
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    await _databaseService.updateTransaction(transaction);
    // The caller mutates the existing instance in place, so the date may
    // have changed and the position in the sorted list could be stale.
    final idx = _transactions.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) {
      _transactions.removeAt(idx);
      _insertSorted(transaction);
    }
    _changes.notify();
  }

  static Future<void> deleteTransaction(Transaction transaction) async {
    await _databaseService.deleteTransaction(transaction);
    _transactions.removeWhere((t) => t.id == transaction.id);
    _changes.notify();
  }

  static Future<void> deleteTransactionsByCategoryId(String categoryId) async {
    await _databaseService.deleteTransactionsByCategoryId(categoryId);
    _transactions.removeWhere((t) => t.categoryId == categoryId);
    _changes.notify();
  }

  /// Returns transactions in [fromDate, toDate] inclusive, ordered most recent
  /// first.
  static List<Transaction> getTransactionsByDate(
      DateTime fromDate, DateTime toDate) {
    final lo = _lowerBoundMs(fromDate.millisecondsSinceEpoch);
    final hi = _upperBoundMs(toDate.millisecondsSinceEpoch);
    if (lo >= hi) return const [];
    final out = List<Transaction>.generate(
      hi - lo,
      (i) => _transactions[hi - 1 - i],
      growable: false,
    );
    return out;
  }

  static int getIncomeByDate(DateTime fromDate, DateTime toDate) {
    int total = 0;
    for (final t in _sliceByDate(fromDate, toDate)) {
      final c = CategoriesService.getCategoryById(t.categoryId);
      if (c != null && c.type == CategoryType.income) total += t.amount;
    }
    return total;
  }

  static int getExpenseByDate(DateTime fromDate, DateTime toDate) {
    int total = 0;
    for (final t in _sliceByDate(fromDate, toDate)) {
      final c = CategoriesService.getCategoryById(t.categoryId);
      if (c != null && c.type == CategoryType.expense) total += t.amount;
    }
    return total;
  }

  static int getBalanceByDate(DateTime fromDate, DateTime toDate) {
    int balance = 0;
    for (final t in _sliceByDate(fromDate, toDate)) {
      final c = CategoriesService.getCategoryById(t.categoryId);
      if (c == null) continue;
      balance += c.type == CategoryType.income ? t.amount : -t.amount;
    }
    return balance;
  }

  static int getBalanceUpToDate(DateTime endDate) {
    final cutoff = endDate.millisecondsSinceEpoch;
    final end = _upperBoundMs(cutoff);
    int balance = 0;
    for (var i = 0; i < end; i++) {
      final t = _transactions[i];
      final c = CategoriesService.getCategoryById(t.categoryId);
      if (c == null) continue;
      balance += c.type == CategoryType.income ? t.amount : -t.amount;
    }
    return balance;
  }

  static List<MapEntry<String, int>> getSortedCategoriesSum(
      DateTime fromDate, DateTime toDate) {
    final Map<String, int> categoriesSum = {};
    for (final t in _sliceByDate(fromDate, toDate)) {
      categoriesSum.update(
        t.categoryId,
        (v) => v + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    return categoriesSum.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  static Iterable<Transaction> _sliceByDate(DateTime from, DateTime to) {
    final lo = _lowerBoundMs(from.millisecondsSinceEpoch);
    final hi = _upperBoundMs(to.millisecondsSinceEpoch);
    if (lo >= hi) return const Iterable.empty();
    return _transactions.getRange(lo, hi);
  }

  static void _insertSorted(Transaction t) {
    final i = _lowerBoundMs(t.date.millisecondsSinceEpoch);
    _transactions.insert(i, t);
  }

  /// First index `i` where `_transactions[i].date.ms >= target`.
  static int _lowerBoundMs(int target) {
    int lo = 0;
    int hi = _transactions.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_transactions[mid].date.millisecondsSinceEpoch < target) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// First index `i` where `_transactions[i].date.ms > target`.
  static int _upperBoundMs(int target) {
    int lo = 0;
    int hi = _transactions.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_transactions[mid].date.millisecondsSinceEpoch <= target) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

class _TransactionsChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
