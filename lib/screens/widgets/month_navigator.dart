import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthNavigator extends StatelessWidget implements PreferredSizeWidget {
  const MonthNavigator({
    required this.date,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  final DateTime date;
  final VoidCallback onPrev;

  /// `null` disables the next button (used to cap forward navigation).
  final VoidCallback? onNext;

  static const double _height = 42;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = '${DateFormat.MMMM().format(date)} '
        '${DateFormat.y().format(date)}';

    return SizedBox(
      height: _height,
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }
}
