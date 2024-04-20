import 'package:uuid/uuid.dart';

import 'category_model.dart';

const _uuid = Uuid();

class Transaction {
  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
  });

  static create({
    required amount,
    required category,
    required date,
    required note,
  }) {
    return Transaction(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
  }

  final String id;
  // Amount in cents
  int amount;
  String note;
  Category category;
  DateTime date;
}
