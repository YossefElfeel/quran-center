import 'package:flutter/material.dart';

/// زر رئيسي كبير (≥56dp) — موحّد عبر التطبيق. لو [onPressed] = null يبقى معطّل.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final IconData? icon = this.icon;
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}
