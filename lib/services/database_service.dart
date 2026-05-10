import 'package:expense_tracker/models/category_model.dart' as cm;
import 'package:expense_tracker/models/transaction_model.dart' as tm;
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    return openDatabase(
      join(await getDatabasesPath(), 'expense_tracker.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            iconCode INTEGER NOT NULL,
            colorCode INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            position INTEGER NOT NULL
          );
          ''');

        await db.execute('''
          INSERT INTO categories (id, iconCode, colorCode, name, type, position)
          VALUES
            ('a864fb77-c575-4fda-ab3e-20f724660243', 0xe482, 0xFF43A047, 'Salary', 'income', 0),
            ('f7ec8fc8-7fbd-4dcc-bf21-4a5a66166825', 0xe6f2, 0xFF7CB342, 'Freelance', 'income', 1),
            ('48f7a130-311e-447c-84f3-c78c2c9bd5ef', 0xe13e, 0xFFEC407A, 'Gifts', 'income', 2),
            ('5eb25f89-7118-42d0-bcaf-2d4dadb7ecef', 0xe040, 0xFFFDD835, 'Investments', 'income', 3),
            ('69d04efc-39f0-46ad-a859-202fe0609074', 0xe395, 0xFF1E88E5, 'Groceries', 'expense', 4),
            ('9af72884-1b66-445a-8f2f-aed8d2707637', 0xe532, 0xFFFB8C00, 'Dining', 'expense', 5),
            ('d95d3aa9-a8ed-4b68-a4c5-3be549cc0484', 0xe1d5, 0xFF5E35B1, 'Transport', 'expense', 6),
            ('c38fb8c2-c92f-4188-888e-9a2549e129c0', 0xe318, 0xFFFFB300, 'Housing', 'expense', 7),
            ('190fa3fa-a29b-4873-bf66-f19cf97fca0c', 0xe50d, 0xFF00ACC1, 'Bills', 'expense', 8),
            ('40231457-9c81-41d8-983d-12f094177940', 0xe305, 0xFFC0CA33, 'Health', 'expense', 9),
            ('c999c52e-7379-4b2f-81cd-ca13f0a130a6', 0xe39a, 0xFFD81B60, 'Shopping', 'expense', 10),
            ('3b8a9e3b-bc20-4ead-8e92-8e4ccd11fb0a', 0xe40d, 0xFFAB47BC, 'Entertainment', 'expense', 11),
            ('7ddd138c-2709-4715-932c-9c821f91a871', 0xe297, 0xFF26A69A, 'Travel', 'expense', 12),
            ('4913205f-4482-4d2c-8889-999dc46a594a', 0xf0555, 0xFF78909C, 'Other', 'expense', 13);
        ''');

        await db.execute(
          '''
          CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY NOT NULL,
            amount INTEGER NOT NULL,
            categoryId TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY (categoryId) REFERENCES categories (id)
          );
          ''',
        );

        await _createForecastingTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createForecastingTables(db);
        }
      },
      version: 2,
    );
  }

  static Future<void> _createForecastingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS forecasts (
        id TEXT PRIMARY KEY,
        generated_at INTEGER NOT NULL,
        target TEXT NOT NULL,
        category_id TEXT,
        horizon_days INTEGER NOT NULL,
        model_name TEXT NOT NULL,
        model_version TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS forecast_points (
        forecast_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        predicted_cents INTEGER NOT NULL,
        lower_cents INTEGER,
        upper_cents INTEGER,
        PRIMARY KEY (forecast_id, date),
        FOREIGN KEY (forecast_id) REFERENCES forecasts(id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_forecasts_target '
      'ON forecasts(target, generated_at DESC);',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_forecasts_category '
      'ON forecasts(category_id, generated_at DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS model_metadata (
        name TEXT NOT NULL,
        version TEXT NOT NULL,
        trained_at INTEGER NOT NULL,
        metrics_json TEXT,
        artefact_path TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (name, version)
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_model_active '
      'ON model_metadata(is_active);',
    );
  }

  Future<List<cm.Category>> getAllCategories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');

    final categories = List.generate(
      maps.length,
      (i) {
        return cm.Category(
          id: maps[i]['id'],
          enabled: maps[i]['enabled'] == 1,
          icon: IconData(maps[i]['iconCode'], fontFamily: 'MaterialIcons'),
          color: Color(maps[i]['colorCode']),
          name: maps[i]['name'],
          type: maps[i]['type'] == 'income'
              ? cm.CategoryType.income
              : cm.CategoryType.expense,
          position: maps[i]['position'],
        );
      },
    );
    return categories..sort((a, b) => a.position.compareTo(b.position));
  }

  Future<void> insertCategory(cm.Category category) async {
    final Database db = await database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(cm.Category category) async {
    final Database db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(cm.Category category) async {
    final Database db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<List<tm.Transaction>> getAllTransactions() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');

    return List.generate(
      maps.length,
      (i) {
        return tm.Transaction(
          id: maps[i]['id'],
          categoryId: maps[i]['categoryId'],
          amount: maps[i]['amount'],
          date: DateTime.parse(maps[i]['date']),
          note: maps[i]['note'],
        );
      },
    );
  }

  Future<void> insertTransaction(tm.Transaction transaction) async {
    final Database db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(tm.Transaction transaction) async {
    final Database db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(tm.Transaction transaction) async {
    final Database db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransactionsByCategoryId(String categoryId) async {
    final Database db = await database;
    await db.delete(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }

  /// Resets the shared database connection. For use in tests only.
  @visibleForTesting
  static void resetForTesting() {
    _database = null;
  }
}
