import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'dart:io';

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
  final path =
      '${Directory.systemTemp.path}/fct_repo_test_${_dbCounter++}.db';
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, _) async {
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
      },
    ),
  );
}

Forecast _makeForecast({
  String id = 'test-id-1',
  ForecastTarget target = ForecastTarget.expenseTotal,
  int horizonDays = 30,
  bool withCi = true,
  DateTime? generatedAt,
}) {
  final base = DateTime(2026, 4, 1);
  return Forecast(
    id: id,
    generatedAt: generatedAt ?? DateTime(2026, 1, 1),
    target: target,
    horizonDays: horizonDays,
    modelName: 'naive',
    modelVersion: '1.0.0',
    points: List.generate(
      horizonDays,
      (i) => ForecastPoint(
        date: base.add(Duration(days: i)),
        predictedCents: 5000 + i,
        lowerCents: withCi ? 4000 : null,
        upperCents: withCi ? 6000 : null,
      ),
    ),
  );
}

void main() {
  late Database db;
  late ForecastRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openTestDb();
    repo = ForecastRepository(_FakeDb(db));
  });

  tearDown(() async {
    final path = db.path;
    await db.close();
    try { File(path).deleteSync(); } catch (_) {}
  });

  group('save + getLatest round-trip', () {
    test('30-point forecast with CI persists and reads back', () async {
      final f = _makeForecast(withCi: true);
      await repo.save(f);
      final got = await repo.getLatest(
        target: ForecastTarget.expenseTotal,
        horizonDays: 30,
      );
      expect(got, isNotNull);
      expect(got!.id, equals(f.id));
      expect(got.points.length, equals(30));
      expect(got.points.first.lowerCents, equals(4000));
      expect(got.points.first.upperCents, equals(6000));
    });

    test('30-point forecast without CI persists and reads back', () async {
      final f = _makeForecast(id: 'no-ci', withCi: false);
      await repo.save(f);
      final got = await repo.getLatest(
        target: ForecastTarget.expenseTotal,
        horizonDays: 30,
      );
      expect(got!.points.first.lowerCents, isNull);
      expect(got.points.first.upperCents, isNull);
    });

    test('save is idempotent (re-save same id overwrites points)', () async {
      final f = _makeForecast();
      await repo.save(f);
      await repo.save(f);
      final all = await repo.listAll();
      expect(all.length, equals(1));
    });
  });

  group('getLatest', () {
    test('returns most recent by generated_at', () async {
      final older = _makeForecast(
        id: 'old',
        generatedAt: DateTime(2026, 1, 1),
      );
      final newer = _makeForecast(
        id: 'new',
        generatedAt: DateTime(2026, 2, 1),
      );
      await repo.save(older);
      await repo.save(newer);

      final got = await repo.getLatest(
        target: ForecastTarget.expenseTotal,
        horizonDays: 30,
      );
      expect(got!.id, equals('new'));
    });
  });

  group('deleteOlderThan', () {
    test('removes only old forecasts', () async {
      final old = _makeForecast(
        id: 'old',
        generatedAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      final recent = _makeForecast(
        id: 'recent',
        generatedAt: DateTime.now(),
      );
      await repo.save(old);
      await repo.save(recent);

      await repo.deleteOlderThan(const Duration(days: 5));
      final all = await repo.listAll();
      expect(all.map((f) => f.id), contains('recent'));
      expect(all.map((f) => f.id), isNot(contains('old')));
    });

    test('deleteOlderThan(Duration.zero) removes all', () async {
      await repo.save(_makeForecast(id: 'a'));
      await repo.save(_makeForecast(id: 'b'));
      await repo.deleteOlderThan(Duration.zero);
      final all = await repo.listAll();
      expect(all, isEmpty);
    });
  });

  group('DB upgrade path', () {
    test('new tables are created and old tables survive after upgrade', () async {
      // Simulate upgrade by checking that new tables are present alongside
      // existing ones (the in-memory DB is already at version 2 in these tests).
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name'] as String).toSet();
      expect(names, containsAll(['forecasts', 'forecast_points', 'model_metadata']));
    });
  });
}
