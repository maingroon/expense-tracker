import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/widgets/buttons_presets.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
  static const maxAmountLengthBeforeDot = 8;
  static const maxAmountLengthAfterDot = 2;

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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final transaction = Transaction.create(
      amount: _parseAmount(),
      note: _noteController.text,
      date: _selectedDateTime,
      category: _selectedCategory,
    );
    widget.onSave(transaction);
    Navigator.pop(context);
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
      if (parts.length == 1 && _amount.length < maxAmountLengthBeforeDot) {
        setState(() {
          _amount += key;
        });
      } else if (parts.length == 2 &&
          parts[1].length < maxAmountLengthAfterDot) {
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
        padding: const EdgeInsets.all(15),
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 180,
                    ),
                    child: GenericOutlinedIconWithLabelButton(
                      icon: _selectedCategory.icon,
                      label: _selectedCategory.name,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => TransactionCategoryDialodWidget(
                            onCagegorySelected: (category) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  GenericOutlinedIconButton(
                    icon: Icons.notes,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => TransactionNoteDialodWidget(
                          noteController: _noteController,
                        ),
                      );
                    },
                  ),
                  GenericOutlinedIconButton(
                    icon: Icons.calendar_month,
                    onPressed: _showDateTimePicker,
                  )
                ],
              ),
            ),
            // keyboard part
            TransactionKeyboardPartWidget(
              onKeyPressed: _processKeyboardKeyPressed,
              onSavePressed: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionCategoryDialodWidget extends StatelessWidget {
  const TransactionCategoryDialodWidget({
    super.key,
    required this.onCagegorySelected,
  });

  final void Function(Category) onCagegorySelected;

  List<Shadow> _getCategoryIconShadows() {
    if (ThemeProvider().getCurrentBrightness() == Brightness.light) {
      return const [
        Shadow(
          blurRadius: 5,
          color: Colors.grey,
          offset: Offset(1, 1),
        ),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoriesService.categories;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 20,
          right: 20,
          left: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              ),
              child: const Text(
                'Category',
                style: TextStyle(fontSize: 20),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (ctx, index) {
                final category = categories[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      category.icon,
                      color: category.color,
                      shadows: _getCategoryIconShadows(),
                    ),
                    title: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      onCagegorySelected(category);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionNoteDialodWidget extends StatelessWidget {
  const TransactionNoteDialodWidget({super.key, required this.noteController});

  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final noteBeforeUpdate = noteController.text;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(
                top: 25,
                bottom: 15,
                left: 25,
                right: 25,
              ),
              child: const Text(
                'Note',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                autofocus: true,
                controller: noteController,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 15,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      noteController.text = noteBeforeUpdate;
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionKeyboardPartWidget extends StatelessWidget {
  const TransactionKeyboardPartWidget({
    required this.onKeyPressed,
    required this.onSavePressed,
    super.key,
  });

  final void Function(String) onKeyPressed;
  final void Function() onSavePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButtonWidget('7'),
              _buildKeyboardButtonWidget('8'),
              _buildKeyboardButtonWidget('9'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButtonWidget('4'),
              _buildKeyboardButtonWidget('5'),
              _buildKeyboardButtonWidget('6'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButtonWidget('1'),
              _buildKeyboardButtonWidget('2'),
              _buildKeyboardButtonWidget('3'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButtonWidget('.'),
              _buildKeyboardButtonWidget('0'),
              _buildSaveButtonWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardButtonWidget(String key) {
    return TextButton(
      onPressed: () => onKeyPressed(key),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButtonWidget() {
    return OutlinedButton(
      onPressed: onSavePressed,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(15),
      ),
      child: const Icon(Icons.done),
    );
  }
}
