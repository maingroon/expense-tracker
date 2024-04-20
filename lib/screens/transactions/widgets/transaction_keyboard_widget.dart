import 'package:flutter/material.dart';

class TransactionKeyboardWidget extends StatelessWidget {
  const TransactionKeyboardWidget({
    required this.onKeyTap,
    required this.onSave,
    super.key,
  });

  final void Function(String) onKeyTap;
  final void Function() onSave;

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
              _buildKeyboardButtonWidget('/'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButtonWidget('4'),
              _buildKeyboardButtonWidget('5'),
              _buildKeyboardButtonWidget('6'),
              _buildKeyboardButtonWidget('*'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButtonWidget('1'),
              _buildKeyboardButtonWidget('2'),
              _buildKeyboardButtonWidget('3'),
              _buildKeyboardButtonWidget('-'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyboardButtonWidget('.'),
              _buildKeyboardButtonWidget('0'),
              _buildSaveButtonWidget(),
              _buildKeyboardButtonWidget('+'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardButtonWidget(String key) {
    return TextButton(
      onPressed: () => onKeyTap(key),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 25,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButtonWidget() {
    return OutlinedButton(
      onPressed: onSave,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(15),
      ),
      child: const Icon(Icons.done),
    );
  }
}
