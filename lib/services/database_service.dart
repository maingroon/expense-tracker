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
            id TEXT PRIMARY KEY,
            iconCode INTEGER,
            colorCode INTEGER,
            name TEXT,
            type TEXT,
            position INTEGER
          );
          ''');
        await db.execute(
          '''
          CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY,
            amount INTEGER,
            categoryId TEXT,
            date TEXT,
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
}
