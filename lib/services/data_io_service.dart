import 'dart:convert';
import 'dart:io';

import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart' as tm;
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ImportResult {
  ImportResult({required this.categories, required this.transactions});
  final int categories;
  final int transactions;
}

class DataIOService {
  DataIOService._();

  static const int _schemaVersion = 1;
  static const String _exportPrefix = 'expense_tracker_export_';

  static Future<Directory> exportsDirectory() async {
    final dir = Directory(p.join(await getDatabasesPath(), 'exports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> exportToFile() async {
    final dir = await exportsDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(p.join(dir.path, '$_exportPrefix$ts.json'));
    final payload = _serialize(
      CategoriesService.categories,
      TransactionsService.transactions,
    );
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  static Future<List<File>> listExportFiles() async {
    final dir = await exportsDirectory();
    final entries = await dir.list().toList();
    final files = entries
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith(_exportPrefix) &&
            f.path.endsWith('.json'))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  static Future<ImportResult> importFromFile(File file,
      {bool replaceExisting = true}) async {
    final raw = await file.readAsString();
    return importFromJsonString(raw, replaceExisting: replaceExisting);
  }

  static Future<ImportResult> importFromAsset(String assetPath,
      {bool replaceExisting = true}) async {
    final raw = await rootBundle.loadString(assetPath);
    return importFromJsonString(raw, replaceExisting: replaceExisting);
  }

  static Future<ImportResult> importFromJsonString(String json,
      {bool replaceExisting = true}) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root must be a JSON object');
    }
    final version = decoded['version'];
    if (version is! int || version != _schemaVersion) {
      throw FormatException(
          'Unsupported export schema version: $version (expected $_schemaVersion)');
    }
    final categoryMaps = (decoded['categories'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final txMaps = (decoded['transactions'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    final db = DatabaseService();
    final raw = await db.database;

    if (replaceExisting) {
      await raw.delete('transactions');
      await raw.delete('categories');
    }

    await raw.transaction((txn) async {
      for (final m in categoryMaps) {
        await txn.insert('categories', _categoryRow(m),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final m in txMaps) {
        await txn.insert('transactions', _transactionRow(m),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    await CategoriesService.init();
    await TransactionsService.init();

    return ImportResult(
      categories: categoryMaps.length,
      transactions: txMaps.length,
    );
  }

  static Map<String, dynamic> _serialize(
      List<Category> categories, List<tm.Transaction> transactions) {
    return {
      'version': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories
          .map((c) => {
                'id': c.id,
                'enabled': c.enabled,
                'iconCode': c.icon.codePoint,
                'colorCode': c.color.toARGB32(),
                'name': c.name,
                'type': c.type.name,
                'position': c.position,
              })
          .toList(),
      'transactions': transactions
          .map((t) => {
                'id': t.id,
                'categoryId': t.categoryId,
                'amount': t.amount,
                'date': t.date.toIso8601String(),
                'note': t.note,
              })
          .toList(),
    };
  }

  static Map<String, Object?> _categoryRow(Map<String, dynamic> m) {
    return {
      'id': m['id'],
      'enabled': (m['enabled'] == true) ? 1 : 0,
      'iconCode': m['iconCode'],
      'colorCode': m['colorCode'],
      'name': m['name'],
      'type': m['type'],
      'position': m['position'],
    };
  }

  static Map<String, Object?> _transactionRow(Map<String, dynamic> m) {
    return {
      'id': m['id'],
      'categoryId': m['categoryId'],
      'amount': m['amount'],
      'date': m['date'],
      'note': m['note'] ?? '',
    };
  }
}

