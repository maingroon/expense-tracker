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
            ('fa4c83ce-a112-4e63-9fb9-e04aeb5f7124', 0xe482, 0x99319B00, 'Salary', 'income', 0),
            ('43690238-488a-449e-86fc-8fe069299ca8', 0xe67f, 0x990CC100, 'Stocks', 'income', 1),
            ('57fd6c50-2fc3-466d-8781-228019612f2c', 0xe040, 0x99EAEE00, 'Investments', 'income', 2),
            ('fefc2994-cbf3-48a5-b18c-15481025f714', 0xe59c, 0x99007CC2, 'Food', 'expense', 3),
            ('280ba54e-d106-485c-af46-010235887369', 0xe1d5, 0x994700D5, 'Transport', 'expense', 4),
            ('0488e1a1-af67-4b71-994f-e8dd6b722fc3', 0xe318, 0x99D57E00, 'House', 'expense', 5),
            ('4c26bc18-14ce-494c-be44-93e2f98a83fe', 0xe559, 0x991A9D00, 'Education', 'expense', 6),
            ('ecafc3f1-2be4-4710-b2ba-e5dadf08dfe2', 0xe1d2, 0x99009D9D, 'Sport', 'expense', 7),
            ('7f200cc4-e09d-444f-ae2b-4082f8078b74', 0xe305, 0x9996B000, 'Health', 'expense', 8),
            ('6118e480-473e-4d18-82eb-1b9a9d1be07f', 0xe5e8, 0x99DCD200, 'Entertainment', 'expense', 9),
            ('58e85735-faf5-4047-8884-8ed9237cf0d1', 0xe39a, 0x99DC006B, 'Shopping', 'expense', 10),
            ('7631f605-444b-416a-8427-8ee94c827408', 0xf0555, 0x99B9B9B9, 'Other', 'expense', 11);
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
      },
      version: 1,
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
}
