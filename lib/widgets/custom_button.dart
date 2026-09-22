import 'package:flutter/material.dart';

/// Another purely presentational widget -> StatelessWidget.
/// Takes a label + callback, renders itself, and nothing else.
class CustomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool outlined;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label),
      ],
    );

    if (outlined) {
      return OutlinedButton(onPressed: onPressed, child: child);
    }
    return ElevatedButton(onPressed: onPressed, child: child);
  }
}
