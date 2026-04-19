import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Category {
  Category({
    required this.id,
    required this.icon,
    required this.color,
    required this.name,
    required this.type,
    required this.position,
    this.enabled = true,
  });

  static create({
    required icon,
    required color,
    required name,
    required type,
    required position,
    enabled = true,
  }) {
    return Category(
      id: _uuid.v4(),
      enabled: enabled,
      icon: icon,
      color: color,
      name: name,
      type: type,
      position: position,
    );
  }

  final String id;

  bool enabled;
  IconData icon;
  Color color;
  String name;
  CategoryType type;
  int position;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enabled': enabled ? 1 : 0,
      'iconCode': icon.codePoint.toString(),
      'colorCode': color.toARGB32().toString(),
      'name': name,
      'type': type.toString().split('.').last,
      'position': position,
    };
  }
}

enum CategoryType {
  income,
  expense;

  static IconData getIcon(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return Icons.arrow_upward;
      case CategoryType.expense:
        return Icons.arrow_downward;
    }
  }

  static String getName(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return 'Income';
      case CategoryType.expense:
        return 'Expense';
    }
  }

  static Color getColor(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return Colors.green;
      case CategoryType.expense:
        return Colors.red;
    }
  }
}

enum CategorySaveMode {
  create,
  edit,
}
