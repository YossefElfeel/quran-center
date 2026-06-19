import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';

/// رسائل سناك‌بار موحّدة (نجاح/خطأ/معلومة) — يستبدل النداءات المتناثرة.
abstract final class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, context.palette.success, Icons.check_circle);

  static void error(BuildContext context, String message) =>
      _show(context, message, context.palette.error, Icons.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, context.palette.info, Icons.info);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
