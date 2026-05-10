import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Metadata describing a registered model artefact.
class ModelMetadata {
  final String name;
  final String version;
  final DateTime trainedAt;
  final String? metricsJson;
  final String artefactPath;
  final bool isActive;

  const ModelMetadata({
    required this.name,
    required this.version,
    required this.trainedAt,
    this.metricsJson,
    required this.artefactPath,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'version': version,
        'trained_at': trainedAt.millisecondsSinceEpoch,
        'metrics_json': metricsJson,
        'artefact_path': artefactPath,
        'is_active': isActive ? 1 : 0,
      };

  factory ModelMetadata.fromMap(Map<String, dynamic> map) => ModelMetadata(
        name: map['name'] as String,
        version: map['version'] as String,
        trainedAt: DateTime.fromMillisecondsSinceEpoch(
          map['trained_at'] as int,
        ),
        metricsJson: map['metrics_json'] as String?,
        artefactPath: map['artefact_path'] as String,
        isActive: (map['is_active'] as int) == 1,
      );
}

class ForecastRepository {
  ForecastRepository(this._db);
  final DatabaseService _db;

  /// Persists [forecast] and its points.
  ///
  /// If a forecast with the same id already exists its points are replaced,
  /// making repeated saves idempotent.
  Future<void> save(Forecast forecast) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
        'forecasts',
        {
          'id': forecast.id,
          'generated_at': forecast.generatedAt.millisecondsSinceEpoch,
          'target': forecast.target.name,
          'category_id': forecast.categoryId,
          'horizon_days': forecast.horizonDays,
          'model_name': forecast.modelName,
          'model_version': forecast.modelVersion,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'forecast_points',
        where: 'forecast_id = ?',
        whereArgs: [forecast.id],
      );

      for (final p in forecast.points) {
        await txn.insert('forecast_points', {
          'forecast_id': forecast.id,
          'date': p.date.millisecondsSinceEpoch,
          'predicted_cents': p.predictedCents,
          'lower_cents': p.lowerCents,
          'upper_cents': p.upperCents,
        });
      }
    });
  }

  /// Returns the most-recently generated forecast matching the given criteria,
  /// or `null` if none exists.
  Future<Forecast?> getLatest({
    required ForecastTarget target,
    String? categoryId,
    required int horizonDays,
  }) async {
    final db = await _db.database;

    final String catClause =
        categoryId == null ? 'category_id IS NULL' : 'category_id = ?';
    final List<Object?> args = categoryId == null
        ? [target.name, horizonDays]
        : [target.name, horizonDays, categoryId];

    final rows = await db.rawQuery('''
      SELECT * FROM forecasts
      WHERE target = ? AND horizon_days = ? AND $catClause
      ORDER BY generated_at DESC
      LIMIT 1
    ''', args);

    if (rows.isEmpty) return null;
    return _rowToForecast(db, rows.first);
  }

  /// Returns all persisted forecasts ordered by [generatedAt] descending.
  Future<List<Forecast>> listAll() async {
    final db = await _db.database;
    final rows = await db.query('forecasts', orderBy: 'generated_at DESC');
    final forecasts = <Forecast>[];
    for (final row in rows) {
      forecasts.add(await _rowToForecast(db, row));
    }
    return forecasts;
  }

  /// Deletes all forecasts (and their points) older than [age].
  Future<void> deleteOlderThan(Duration age) async {
    final db = await _db.database;
    final cutoff = DateTime.now().subtract(age).millisecondsSinceEpoch;
    final oldIds = await db.rawQuery(
      'SELECT id FROM forecasts WHERE generated_at < ?',
      [cutoff],
    );
    for (final row in oldIds) {
      final id = row['id'] as String;
      await db.delete(
        'forecast_points',
        where: 'forecast_id = ?',
        whereArgs: [id],
      );
      await db.delete('forecasts', where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Returns the currently active model metadata, or `null` if none is set.
  Future<ModelMetadata?> getActiveModel() async {
    final db = await _db.database;
    final rows = await db.query(
      'model_metadata',
      where: 'is_active = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ModelMetadata.fromMap(rows.first);
  }

  /// Registers [m] as the active model, deactivating all others.
  Future<void> setActiveModel(ModelMetadata m) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('model_metadata', {'is_active': 0});
      await txn.insert(
        'model_metadata',
        m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'model_metadata',
        {'is_active': 1},
        where: 'name = ? AND version = ?',
        whereArgs: [m.name, m.version],
      );
    });
  }

  Future<Forecast> _rowToForecast(
    Database db,
    Map<String, dynamic> row,
  ) async {
    final id = row['id'] as String;
    final pointRows = await db.query(
      'forecast_points',
      where: 'forecast_id = ?',
      whereArgs: [id],
      orderBy: 'date ASC',
    );
    final points = pointRows
        .map(
          (p) => ForecastPoint(
            date: DateTime.fromMillisecondsSinceEpoch(p['date'] as int),
            predictedCents: p['predicted_cents'] as int,
            lowerCents: p['lower_cents'] as int?,
            upperCents: p['upper_cents'] as int?,
          ),
        )
        .toList();

    return Forecast(
      id: id,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['generated_at'] as int,
      ),
      target: ForecastTarget.values.byName(row['target'] as String),
      categoryId: row['category_id'] as String?,
      horizonDays: row['horizon_days'] as int,
      modelName: row['model_name'] as String,
      modelVersion: row['model_version'] as String,
      points: points,
    );
  }
}
