import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/models/forecast_request_model.dart';
import 'package:expense_tracker/screens/forecast/forecast_screen.dart';
import 'package:expense_tracker/screens/forecast/widgets/forecast_chart.dart';
import 'package:expense_tracker/screens/forecast/widgets/forecast_summary_card.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'package:expense_tracker/services/forecasting_service.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class _MockForecastingService implements ForecastingService {
  _MockForecastingService({this.enoughHistory = true});

  final bool enoughHistory;
  int forecastCallCount = 0;

  @override
  Future<bool> get hasEnoughHistory async => enoughHistory;

  @override
  Future<int> get availableHistoryDays async => enoughHistory ? 90 : 0;

  @override
  Future<Forecast> forecast(ForecastRequest request) async {
    forecastCallCount++;
    return _buildForecast(request);
  }

  static Forecast _buildForecast(ForecastRequest request) {
    final base = DateTime(2026, 4, 1);
    return Forecast.create(
      target: request.target,
      categoryId: request.categoryId,
      horizonDays: request.horizonDays,
      modelName: 'mock',
      modelVersion: '0.0.1',
      points: List.generate(
        request.horizonDays,
        (i) => ForecastPoint(
          date: base.add(Duration(days: i)),
          predictedCents: 5000 + i * 10,
          lowerCents: 4000,
          upperCents: 6000,
        ),
      ),
    );
  }
}

class _FakeDb extends DatabaseService {
  _FakeDb(this._testDb);
  final Database _testDb;

  @override
  Future<Database> get database async => _testDb;
}

int _dbCounter = 0;

Future<Database> _openTestDb() async {
  final path =
      '${Directory.systemTemp.path}/fct_screen_test_${_dbCounter++}.db';
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _buildTestWidget({
  required ForecastingService forecastSvc,
  required ForecastRepository repo,
  required AggregationService aggSvc,
}) {
  return MultiProvider(
    providers: [
      Provider<ForecastingService>.value(value: forecastSvc),
      Provider<ForecastRepository>.value(value: repo),
      Provider<AggregationService>.value(value: aggSvc),
    ],
    child: const MaterialApp(home: ForecastScreen()),
  );
}

void main() {
  late Database db;
  late ForecastRepository repo;
  late AggregationService aggSvc;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

  setUp(() async {
    db = await _openTestDb();
    final fakeDb = _FakeDb(db);
    repo = ForecastRepository(fakeDb);
    aggSvc = AggregationService(fakeDb);
  });

  tearDown(() async {
    final path = db.path;
    await db.close();
    try { File(path).deleteSync(); } catch (_) {}
  });

  testWidgets('renders summary card and chart with mock service returning 30 points',
      (tester) async {
    final svc = _MockForecastingService();
    await tester.pumpWidget(
      _buildTestWidget(forecastSvc: svc, repo: repo, aggSvc: aggSvc),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ForecastSummaryCard), findsOneWidget);
    expect(find.byType(ForecastChart), findsOneWidget);
  });

  testWidgets('insufficient history state renders correctly', (tester) async {
    final svc = _MockForecastingService(enoughHistory: false);
    await tester.pumpWidget(
      _buildTestWidget(forecastSvc: svc, repo: repo, aggSvc: aggSvc),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not enough history'), findsOneWidget);
    expect(find.byType(ForecastSummaryCard), findsNothing);
  });

  testWidgets('horizon change triggers a new forecast call', (tester) async {
    final svc = _MockForecastingService();
    await tester.pumpWidget(
      _buildTestWidget(forecastSvc: svc, repo: repo, aggSvc: aggSvc),
    );
    await tester.pumpAndSettle();

    final callsBefore = svc.forecastCallCount;

    // Tap the 7d segment button.
    await tester.tap(find.text('7d'));
    await tester.pumpAndSettle();

    expect(svc.forecastCallCount, greaterThan(callsBefore));
  });
}
