import 'package:flutter/material.dart';

class GenericOutlinedIconButton extends StatelessWidget {
  const GenericOutlinedIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.iconSize,
    super.key,
  });

  final IconData icon;
  final void Function() onPressed;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 10,
        ),
      ),
      child: Icon(
        icon,
        size: iconSize ?? 30,
        color: iconColor,
      ),
    );
  }
}

class GenericOutlinedIconWithLabelButton extends StatelessWidget {
  const GenericOutlinedIconWithLabelButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.iconSize,
    super.key,
  });

  final IconData icon;
  final String label;
  final void Function() onPressed;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: iconSize ?? 30,
        color: iconColor,
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
    );
  }
}
