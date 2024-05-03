import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Transaction {
  Transaction({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.date,
    required this.note,
  });

  static create({
    required categoryId,
    required amount,
    required date,
    required note,
  }) {
    return Transaction(
      id: _uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      date: date,
      note: note,
    );
  }

  final String id;
  String categoryId;
  // Amount in cents
  int amount;
  String note;
  DateTime date;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}

enum TransactionSaveMode {
  create,
  edit,
}
