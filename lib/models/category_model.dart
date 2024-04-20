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
  });

  static create({
    required icon,
    required color,
    required name,
    required type,
  }) {
    return Category(
      id: _uuid.v4(),
      icon: icon,
      color: color,
      name: name,
      type: type,
    );
  }

  final String id;

  IconData icon;
  Color color;
  String name;
  CategoryType type;
}

enum CategoryType {
  income,
  expense,
}
