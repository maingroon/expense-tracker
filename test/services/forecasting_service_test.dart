import 'dart:io';

import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/models/forecast_request_model.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'package:expense_tracker/services/forecasting_exceptions.dart';
import 'package:expense_tracker/services/forecasting_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeDb extends DatabaseService {
  _FakeDb(this._testDb);
  final Database _testDb;

  @override
  Future<Database> get database async => _testDb;
}

int _dbCounter = 0;

Future<Database> _openTestDb() async {
  // Use unique file paths to avoid sqflite_common_ffi's shared in-memory cache.
  final path =
      '${Directory.systemTemp.path}/fct_svc_test_${_dbCounter++}.db';
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 2,
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
        await db.execute('''
          CREATE TABLE forecasts (
            id TEXT PRIMARY KEY,
            generated_at INTEGER NOT NULL,
            target TEXT NOT NULL,
            category_id TEXT,
            horizon_days INTEGER NOT NULL,
            model_name TEXT NOT NULL,
            model_version TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE forecast_points (
            forecast_id TEXT NOT NULL,
            date INTEGER NOT NULL,
            predicted_cents INTEGER NOT NULL,
            lower_cents INTEGER,
            upper_cents INTEGER,
            PRIMARY KEY (forecast_id, date)
          )
        ''');
        await db.execute('''
          CREATE TABLE model_metadata (
            name TEXT NOT NULL,
            version TEXT NOT NULL,
            trained_at INTEGER NOT NULL,
            metrics_json TEXT,
            artefact_path TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (name, version)
          )
        ''');

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

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}T00:00:00.000';

void main() {
  late Database db;
  late NaiveForecastingService svc;
  late ForecastRepository repo;
  int txCounter = 0;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    txCounter = 0;
    db = await _openTestDb();
    final fakeDb = _FakeDb(db);
    final aggSvc = AggregationService(fakeDb);
    repo = ForecastRepository(fakeDb);
    svc = NaiveForecastingService(aggSvc, repo);

    // Seed 35 days of expense history so the stub has enough data.
    final base = DateTime(2026, 3, 1);
    for (var i = 0; i < 35; i++) {
      final date = base.add(Duration(days: i));
      await db.insert('transactions', {
        'id': 'tx-${txCounter++}',
        'amount': 5000,
        'categoryId': 'expense-cat',
        'date': _isoDate(date),
      });
    }
  });

  tearDown(() async {
    final path = db.path;
    await db.close();
    try { File(path).deleteSync(); } catch (_) {}
  });

  test('stub produces horizonDays points for horizon=30', () async {
    final f = await svc.forecast(
      ForecastRequest(
        target: ForecastTarget.expenseTotal,
        horizonDays: 30,
        asOf: DateTime(2026, 4, 5),
      ),
    );
    expect(f.points.length, equals(30));
  });

  test('stub is deterministic given same history', () async {
    final req = ForecastRequest(
      target: ForecastTarget.expenseTotal,
      horizonDays: 7,
      asOf: DateTime(2026, 4, 5),
    );
    final f1 = await svc.forecast(req);
    final f2 = await svc.forecast(req);

    for (var i = 0; i < f1.points.length; i++) {
      expect(f1.points[i].predictedCents, equals(f2.points[i].predictedCents));
      expect(f1.points[i].lowerCents, equals(f2.points[i].lowerCents));
      expect(f1.points[i].upperCents, equals(f2.points[i].upperCents));
    }
  });

  test('CI bounds: lower <= predicted <= upper for every point', () async {
    final f = await svc.forecast(
      ForecastRequest(
        target: ForecastTarget.expenseTotal,
        horizonDays: 14,
        asOf: DateTime(2026, 4, 5),
      ),
    );
    for (final p in f.points) {
      if (p.lowerCents != null && p.upperCents != null) {
        expect(p.lowerCents, lessThanOrEqualTo(p.predictedCents));
        expect(p.predictedCents, lessThanOrEqualTo(p.upperCents!));
      }
    }
  });

  test('insufficient history throws InsufficientHistoryException', () async {
    // Open a separate, truly empty DB (no transactions seeded).
    final emptyDb = await _openTestDb();
    final fakeEmptyDb = _FakeDb(emptyDb);
    final emptySvc = NaiveForecastingService(
      AggregationService(fakeEmptyDb),
      ForecastRepository(fakeEmptyDb),
    );
    addTearDown(() async {
      final path = emptyDb.path;
      await emptyDb.close();
      try { File(path).deleteSync(); } catch (_) {}
    });

    await expectLater(
      () => emptySvc.forecast(
        ForecastRequest(
          target: ForecastTarget.expenseTotal,
          horizonDays: 7,
          asOf: DateTime(2026, 4, 5),
        ),
      ),
      throwsA(isA<InsufficientHistoryException>()),
    );
  });

  test('calling forecast twice persists two records; getLatest returns newer',
      () async {
    final req = ForecastRequest(
      target: ForecastTarget.expenseTotal,
      horizonDays: 7,
      asOf: DateTime(2026, 4, 5),
    );
    final f1 = await svc.forecast(req);
    // Small delay to ensure different generated_at timestamps.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final f2 = await svc.forecast(req);

    final all = await repo.listAll();
    expect(all.map((f) => f.id), containsAll([f1.id, f2.id]));

    final latest = await repo.getLatest(
      target: ForecastTarget.expenseTotal,
      horizonDays: 7,
    );
    expect(latest!.id, equals(f2.id));
  });
}
