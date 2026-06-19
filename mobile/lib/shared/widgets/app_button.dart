import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// أنواع الأزرار.
enum AppButtonVariant { primary, tonal, outlined, text }

/// زر رئيسي كبير (≥56dp) — موحّد عبر التطبيق.
/// - [onPressed] = null أو [isLoading] = true ⇒ معطّل.
/// - [isLoading] بيعرض مؤشّر تحميل بدل المحتوى.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.variant = AppButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final VoidCallback? effective = disabled ? null : onPressed;
    final ColorScheme cs = Theme.of(context).colorScheme;

    final Color spinnerColor = switch (variant) {
      AppButtonVariant.primary => context.palette.onPrimary,
      AppButtonVariant.tonal => cs.onSecondaryContainer,
      AppButtonVariant.outlined ||
      AppButtonVariant.text => context.palette.primary,
    };

    final Widget content = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: spinnerColor,
            ),
          )
        : Text(label, overflow: TextOverflow.ellipsis);

    final IconData? icon = this.icon;
    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = (icon != null && !isLoading)
            ? ElevatedButton.icon(
                onPressed: effective,
                icon: Icon(icon),
                label: content,
              )
            : ElevatedButton(onPressed: effective, child: content);
      case AppButtonVariant.tonal:
        button = (icon != null && !isLoading)
            ? FilledButton.tonalIcon(
                onPressed: effective,
                icon: Icon(icon),
                label: content,
              )
            : FilledButton.tonal(onPressed: effective, child: content);
      case AppButtonVariant.outlined:
        button = (icon != null && !isLoading)
            ? OutlinedButton.icon(
                onPressed: effective,
                icon: Icon(icon),
                label: content,
              )
            : OutlinedButton(onPressed: effective, child: content);
      case AppButtonVariant.text:
        button = (icon != null && !isLoading)
            ? TextButton.icon(
                onPressed: effective,
                icon: Icon(icon),
                label: content,
              )
            : TextButton(onPressed: effective, child: content);
    }

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
