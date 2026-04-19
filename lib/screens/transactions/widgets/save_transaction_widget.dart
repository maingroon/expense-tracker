import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/widgets/buttons_presets.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  String _amount = '0';
  Category? _selectedCategory;
  late TextEditingController _noteController;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    final whole = widget.transaction.amount ~/ 100;
    final remainder = widget.transaction.amount % 100;
    _amount = whole.toString();
    if (remainder > 0) {
      _amount += '.';
      if (remainder < 10) _amount += '0';
      _amount += remainder.toString();
    }
    _selectedCategory =
        CategoriesService.getCategoryById(widget.transaction.categoryId) ??
            CategoriesService.categories.firstWhere((c) => c.enabled);
    _noteController = TextEditingController(text: widget.transaction.note);
    _selectedDateTime = widget.transaction.date;
  }

  Future<void> _showDateTimePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      currentDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _selectedDateTime.hour,
        minute: _selectedDateTime.minute,
      ),
    );
    if (selectedTime == null) return;

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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final amount = _parseAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    final transaction = Transaction.create(
      categoryId: _selectedCategory!.id,
      amount: amount,
      note: _noteController.text,
      date: _selectedDateTime,
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
    final category = _selectedCategory;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // amount row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 180,
                    ),
                    child: GenericOutlinedIconWithLabelButton(
                      icon: category?.icon ?? Icons.category,
                      label: category?.name ?? '',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => TransactionCategoryDialogWidget(
                            onCategorySelected: (category) {
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
                        builder: (context) => TransactionNoteDialogWidget(
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

class TransactionCategoryDialogWidget extends StatelessWidget {
  const TransactionCategoryDialogWidget({
    super.key,
    required this.onCategorySelected,
  });

  final void Function(Category) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final shadows = context.watch<ThemeProvider>().getIconsShadows();
    final categories =
        CategoriesService.categories.where((c) => c.enabled).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final category = categories[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          category.icon,
                          color: category.color,
                          shadows: shadows,
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
                          onCategorySelected(category);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionNoteDialogWidget extends StatelessWidget {
  const TransactionNoteDialogWidget({super.key, required this.noteController});

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
