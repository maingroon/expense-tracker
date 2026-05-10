import 'package:expense_tracker/services/aggregation_service.dart';
import 'dart:io';

import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Subclasses DatabaseService to inject an in-memory test database.
class _FakeDb extends DatabaseService {
  _FakeDb(this._testDb);
  final Database _testDb;

  @override
  Future<Database> get database async => _testDb;
}

int _dbCounter = 0;

Future<Database> _openTestDb() async {
  final path =
      '${Directory.systemTemp.path}/agg_svc_test_${_dbCounter++}.db';
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            iconCode INTEGER NOT NULL DEFAULT 0,
            colorCode INTEGER NOT NULL DEFAULT 0,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            position INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY NOT NULL,
            amount INTEGER NOT NULL,
            categoryId TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        ''');

        // Seed two categories: one income, one expense.
        await db.insert('categories', {
          'id': 'income-cat',
          'name': 'Salary',
          'type': 'income',
          'iconCode': 0,
          'colorCode': 0,
          'position': 0,
        });
        await db.insert('categories', {
          'id': 'expense-cat',
          'name': 'Groceries',
          'type': 'expense',
          'iconCode': 0,
          'colorCode': 0,
          'position': 1,
        });
      },
    ),
  );
}

String _iso(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}T00:00:00.000';

void main() {
  late Database db;
  late AggregationService svc;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openTestDb();
    svc = AggregationService(_FakeDb(db));
  });

  tearDown(() async {
    final path = db.path;
    await db.close();
    try { File(path).deleteSync(); } catch (_) {}
  });

  group('getDailyTotals', () {
    test('empty DB returns 7 zero rows over 7-day window', () async {
      final from = DateTime(2026, 4, 1);
      final to = DateTime(2026, 4, 7);
      final result = await svc.getDailyTotals(from: from, to: to);
      expect(result.length, equals(7));
      for (final d in result) {
        expect(d.incomeCents, 0);
        expect(d.expenseCents, 0);
        expect(d.netCents, 0);
      }
    });

    test('3 income + 2 expense rows on same day → correct sums', () async {
      const day = '2026-04-05';
      for (var i = 0; i < 3; i++) {
        await db.insert('transactions', {
          'id': 'inc-$i',
          'amount': 1000,
          'categoryId': 'income-cat',
          'date': '${day}T10:00:00.000',
        });
      }
      for (var i = 0; i < 2; i++) {
        await db.insert('transactions', {
          'id': 'exp-$i',
          'amount': 500,
          'categoryId': 'expense-cat',
          'date': '${day}T11:00:00.000',
        });
      }

      final from = DateTime(2026, 4, 5);
      final to = DateTime(2026, 4, 5);
      final result = await svc.getDailyTotals(from: from, to: to);

      expect(result.length, 1);
      expect(result.first.incomeCents, 3000);
      expect(result.first.expenseCents, 1000);
      expect(result.first.netCents, 2000);
    });

    test('non-consecutive transaction days → gap days filled with zeros', () async {
      await db.insert('transactions', {
        'id': 'tx-1',
        'amount': 2000,
        'categoryId': 'income-cat',
        'date': _iso(2026, 4, 1),
      });
      await db.insert('transactions', {
        'id': 'tx-2',
        'amount': 1000,
        'categoryId': 'expense-cat',
        'date': _iso(2026, 4, 3),
      });

      final result = await svc.getDailyTotals(
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 4, 4),
      );
      expect(result.length, 4);
      expect(result[0].incomeCents, 2000); // Apr 1
      expect(result[1].incomeCents, 0);    // Apr 2 (gap)
      expect(result[1].expenseCents, 0);
      expect(result[2].expenseCents, 1000); // Apr 3
      expect(result[3].incomeCents, 0);     // Apr 4 (gap)
    });
  });

  group('getDailyBalance', () {
    test('deposit 100, expense 30, expense 20 → balance series [100, 70, 50]', () async {
      await db.insert('transactions', {
        'id': 'dep',
        'amount': 10000,
        'categoryId': 'income-cat',
        'date': _iso(2026, 4, 1),
      });
      await db.insert('transactions', {
        'id': 'exp-1',
        'amount': 3000,
        'categoryId': 'expense-cat',
        'date': _iso(2026, 4, 2),
      });
      await db.insert('transactions', {
        'id': 'exp-2',
        'amount': 2000,
        'categoryId': 'expense-cat',
        'date': _iso(2026, 4, 3),
      });

      final result = await svc.getDailyBalance(
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 4, 3),
      );
      expect(result.length, 3);
      expect(result[0].netCents, 10000);
      expect(result[1].netCents, 7000);
      expect(result[2].netCents, 5000);
    });
  });

  group('getDailyByCategory', () {
    test('filter by categoryId returns only matching entries', () async {
      await db.insert('transactions', {
        'id': 'tx-inc',
        'amount': 5000,
        'categoryId': 'income-cat',
        'date': _iso(2026, 4, 1),
      });
      await db.insert('transactions', {
        'id': 'tx-exp',
        'amount': 2000,
        'categoryId': 'expense-cat',
        'date': _iso(2026, 4, 1),
      });

      final result = await svc.getDailyByCategory(
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 4, 1),
        categoryIds: ['expense-cat'],
      );
      expect(result.length, 1);
      expect(result.first.categoryId, 'expense-cat');
      expect(result.first.amountCents, -2000);
    });
  });
}
