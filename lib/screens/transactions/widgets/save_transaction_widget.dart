import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/transactions/widgets/transaction_keyboard_widget.dart';
import 'package:flutter/material.dart';

class SaveTransactionWidget extends StatefulWidget {
  const SaveTransactionWidget({
    required this.transaction,
    required this.onSave,
    super.key,
  });

  final Transaction transaction;
  final void Function(Transaction) onSave;

  @override
  State<StatefulWidget> createState() {
    return _SaveExpenseState();
  }
}

class _SaveExpenseState extends State<SaveTransactionWidget> {
  static const MAX_AMOUNT_LENGTH_BEFORE_DOT = 8;
  static const MAX_AMOUNT_LENGTH_AFTER_DOT = 2;

  late String _amount;
  late Category _selectedCategory;
  late TextEditingController _noteController;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _amount = (widget.transaction.amount ~/ 100).toString();
    final remainder = widget.transaction.amount % 100;
    if (remainder > 0) {
      _amount += '.';
      if (remainder < 10) {
        _amount += '0';
      }
      _amount += remainder.toString();
    }
    _selectedCategory = widget.transaction.category;
    _noteController = TextEditingController(text: widget.transaction.note);
    _selectedDateTime = widget.transaction.date;
  }

  void _showDateTimePicker() {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);

    showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      currentDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
    ).then((selectedDate) {
      if (selectedDate != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: now.hour,
            minute: now.minute,
          ),
        ).then((selectedTime) {
          if (selectedTime != null) {
            setState(() {
              _selectedDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
            });
          }
        });
      }
    });
  }

  void _saveTransaction() {
    print(_parseAmount());
    // final enteredTitle = _noteController.text.trim();
    // final enteredAmount = double.tryParse(_amountController.text);
    // final errorField = enteredTitle.isEmpty
    //     ? 'title'
    //     : ((enteredAmount == null || enteredAmount <= 0) ? 'amount' : null);

    // if (errorField != null) {
    //   showDialog(
    //     context: context,
    //     builder: (ctx) => AlertDialog(
    //       title: Text('Invalid $errorField'),
    //       content: Text(
    //         'Please check that $errorField not empty and has a valid value.',
    //       ),
    //       actions: [
    //         OutlinedButton(
    //           onPressed: () {
    //             Navigator.pop(ctx);
    //           },
    //           child: const Text('Okey'),
    //         ),
    //       ],
    //     ),
    //   );
    //   return;
    // }

    // final transaction = Transaction.create(
    //   amount: (double.parse(_amountController.text) * 100).round(),
    //   note: _noteController.text,
    //   date: _selectedDateTime,
    //   category: _selectedCategory,
    // );
    // widget.onSave(transaction);
    // Navigator.pop(context);
  }

  int _parseAmount() {
    final doubleAmount = double.tryParse(_amount);
    if (doubleAmount == null || doubleAmount <= 0) {
      return 0;
    }
    return (doubleAmount * 100).round();
  }

  void _processKeyboardKeyPressed(String key) {
    if (key != '.' && _amount == '0') {
      setState(() {
        _amount = key;
      });
    } else if (key == '.' && !_amount.contains('.')) {
      setState(() {
        _amount += key;
      });
    } else if (key != '.' && _amount != '0') {
      final parts = _amount.split('.');
      if (parts.length == 1 && _amount.length < MAX_AMOUNT_LENGTH_BEFORE_DOT) {
        setState(() {
          _amount += key;
        });
      } else if (parts.length == 2 &&
          parts[1].length < MAX_AMOUNT_LENGTH_AFTER_DOT) {
        setState(() {
          _amount += key;
        });
      }
    }
  }

  void _processBackspacePressed() {
    if (_amount.length > 1) {
      setState(() {
        _amount = _amount.substring(0, _amount.length - 1);
      });
    } else {
      setState(() {
        _amount = '0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: 15 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // amount row
            Padding(
              padding: const EdgeInsets.all(10),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Align(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          clipBehavior: Clip.antiAlias,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Text(
                            _amount,
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      bottom: 10,
                      child: IconButton(
                        onPressed: _processBackspacePressed,
                        icon: const Icon(
                          Icons.backspace,
                          size: 25,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // settings row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => {},
                    icon: Icon(
                      _selectedCategory.icon,
                      size: 30,
                    ),
                    label: Text(
                      _selectedCategory.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          insetPadding: const EdgeInsets.all(20),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  alignment: Alignment.topLeft,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  child: const Text(
                                    'Note',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                                TextField(
                                  controller: _noteController,
                                  autofocus: true,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FilledButton(
                                  onPressed: () => {
                                    Navigator.pop(context),
                                  },
                                  child: const Text('Ok'),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 10,
                      ),
                    ),
                    child: const Icon(
                      Icons.notes,
                      size: 30,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showDateTimePicker(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 10,
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            // keyboard part
            TransactionKeyboardWidget(
              onKeyPressed: _processKeyboardKeyPressed,
              onSavePressed: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }
}
