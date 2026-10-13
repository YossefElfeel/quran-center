import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';

/// رسائل سناك‌بار موحّدة (نجاح/خطأ/معلومة) — يستبدل النداءات المتناثرة.
abstract final class AppSnackbar {
  const AppSnackbar._();

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message,
    context.palette.success,
    Icons.check_circle,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void error(BuildContext context, String message) =>
      _show(context, message, context.palette.error, Icons.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, context.palette.info, Icons.info);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: context.palette.foregroundOn(color),
                  onPressed: onAction,
                )
              : null,
          content: Row(
            children: <Widget>[
              Icon(icon, color: context.palette.foregroundOn(color), size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: context.palette.foregroundOn(color),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
