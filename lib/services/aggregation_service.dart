// Date storage note: the 'transactions' table stores dates as ISO 8601 strings
// (e.g., "2025-02-19T14:30:45.123456"). SQL GROUP BY uses substr(date, 1, 10)
// to extract the YYYY-MM-DD portion for day-level aggregation.
import 'package:expense_tracker/services/database_service.dart';

/// Aggregated daily totals for a single calendar day.
class DailyAggregate {
  /// Local-time midnight for this calendar day.
  final DateTime date;

  /// Sum of income transactions on this day. Always non-negative.
  final int incomeCents;

  /// Sum of expense transactions on this day as a non-negative magnitude.
  final int expenseCents;

  /// In [AggregationService.getDailyTotals]: `incomeCents - expenseCents`.
  /// In [AggregationService.getDailyBalance]: the running end-of-day balance.
  final int netCents;

  const DailyAggregate({
    required this.date,
    required this.incomeCents,
    required this.expenseCents,
    required this.netCents,
  });
}

/// Aggregated daily totals for a single category on a single calendar day.
class DailyCategoryAggregate {
  /// Local-time midnight for this calendar day.
  final DateTime date;

  final String categoryId;

  /// Signed amount in cents: positive for income, negative for expense.
  final int amountCents;

  /// Number of transactions contributing to this aggregate.
  final int txCount;

  const DailyCategoryAggregate({
    required this.date,
    required this.categoryId,
    required this.amountCents,
    required this.txCount,
  });
}

class AggregationService {
  AggregationService(this._db);
  final DatabaseService _db;

  DateTime _toMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  String _toIsoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Returns daily totals between [from] and [to] inclusive.
  ///
  /// Days with no transactions are filled with zero rows so the result always
  /// has exactly `to.difference(from).inDays + 1` entries.
  Future<List<DailyAggregate>> getDailyTotals({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db.database;
    final fromStr = _toIsoDate(_toMidnight(from));
    final toStr = _toIsoDate(_toMidnight(to));

    final rows = await db.rawQuery('''
      SELECT
        substr(t.date, 1, 10) AS day,
        SUM(CASE WHEN c.type = 'income' THEN t.amount ELSE 0 END) AS income,
        SUM(CASE WHEN c.type = 'expense' THEN t.amount ELSE 0 END) AS expense
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      WHERE substr(t.date, 1, 10) >= ? AND substr(t.date, 1, 10) <= ?
      GROUP BY day
      ORDER BY day
    ''', [fromStr, toStr]);

    final byDay = <String, DailyAggregate>{};
    for (final row in rows) {
      final day = row['day'] as String;
      final income = (row['income'] as num?)?.toInt() ?? 0;
      final expense = (row['expense'] as num?)?.toInt() ?? 0;
      byDay[day] = DailyAggregate(
        date: DateTime.parse(day),
        incomeCents: income,
        expenseCents: expense,
        netCents: income - expense,
      );
    }

    return _fillGaps(
      from: _toMidnight(from),
      to: _toMidnight(to),
      map: byDay,
    );
  }

  List<DailyAggregate> _fillGaps({
    required DateTime from,
    required DateTime to,
    required Map<String, DailyAggregate> map,
  }) {
    final result = <DailyAggregate>[];
    var current = from;
    while (!current.isAfter(to)) {
      final key = _toIsoDate(current);
      result.add(
        map[key] ??
            DailyAggregate(
              date: current,
              incomeCents: 0,
              expenseCents: 0,
              netCents: 0,
            ),
      );
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  /// Returns daily per-category totals between [from] and [to] inclusive.
  ///
  /// [categoryIds] restricts output to specific categories; `null` means all.
  /// Days × categories with no activity are **not** zero-filled (sparse).
  Future<List<DailyCategoryAggregate>> getDailyByCategory({
    required DateTime from,
    required DateTime to,
    List<String>? categoryIds,
  }) async {
    final db = await _db.database;
    final fromStr = _toIsoDate(_toMidnight(from));
    final toStr = _toIsoDate(_toMidnight(to));

    String categoryFilter = '';
    final List<Object?> args = [fromStr, toStr];
    if (categoryIds != null && categoryIds.isNotEmpty) {
      final placeholders = List.filled(categoryIds.length, '?').join(', ');
      categoryFilter = 'AND t.categoryId IN ($placeholders)';
      args.addAll(categoryIds);
    }

    final rows = await db.rawQuery('''
      SELECT
        substr(t.date, 1, 10) AS day,
        t.categoryId AS category_id,
        SUM(CASE WHEN c.type = 'income' THEN t.amount ELSE -t.amount END) AS amount,
        COUNT(*) AS tx_count
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      WHERE substr(t.date, 1, 10) >= ? AND substr(t.date, 1, 10) <= ?
      $categoryFilter
      GROUP BY day, category_id
      ORDER BY day, category_id
    ''', args);

    return rows
        .map(
          (row) => DailyCategoryAggregate(
            date: DateTime.parse(row['day'] as String),
            categoryId: row['category_id'] as String,
            amountCents: (row['amount'] as num?)?.toInt() ?? 0,
            txCount: (row['tx_count'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  /// Returns the end-of-day running balance for each day in [[from], [to]].
  ///
  /// Initial balance is computed from all transactions strictly before [from].
  /// The returned [DailyAggregate.netCents] holds the **running balance**,
  /// not the daily net. [incomeCents] and [expenseCents] remain the daily totals.
  Future<List<DailyAggregate>> getDailyBalance({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db.database;
    final fromStr = _toIsoDate(_toMidnight(from));

    final priorRows = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN c.type = 'income' THEN t.amount ELSE -t.amount END) AS net
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      WHERE substr(t.date, 1, 10) < ?
    ''', [fromStr]);

    var running = 0;
    if (priorRows.isNotEmpty && priorRows.first['net'] != null) {
      running = (priorRows.first['net'] as num).toInt();
    }

    final dailyTotals = await getDailyTotals(from: from, to: to);
    return dailyTotals.map((d) {
      running += d.netCents;
      return DailyAggregate(
        date: d.date,
        incomeCents: d.incomeCents,
        expenseCents: d.expenseCents,
        netCents: running,
      );
    }).toList();
  }

  /// Returns the earliest transaction date, or `null` if no transactions exist.
  Future<DateTime?> earliestTransactionDate() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      "SELECT MIN(substr(date, 1, 10)) AS earliest FROM transactions",
    );
    if (rows.isEmpty || rows.first['earliest'] == null) return null;
    return DateTime.parse(rows.first['earliest'] as String);
  }
}
