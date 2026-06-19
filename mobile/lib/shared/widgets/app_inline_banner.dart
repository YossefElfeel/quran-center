import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';

/// نوع البانر.
enum AppBannerKind { offline, syncing, info, success, warning, error }

/// بانر داخلي خفيف (أوفلاين/مزامنة/معلومة) — شريط ملوّن مع أيقونة وإجراء اختياري.
class AppInlineBanner extends StatelessWidget {
  const AppInlineBanner({
    required this.message,
    this.kind = AppBannerKind.info,
    this.icon,
    this.onAction,
    this.actionLabel,
    super.key,
  });

  final String message;
  final AppBannerKind kind;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  (Color, IconData) _style(AppPalette p) {
    switch (kind) {
      case AppBannerKind.offline:
        return (p.offline, Icons.cloud_off);
      case AppBannerKind.syncing:
        return (p.syncPending, Icons.sync);
      case AppBannerKind.info:
        return (p.info, Icons.info_outline);
      case AppBannerKind.success:
        return (p.success, Icons.check_circle_outline);
      case AppBannerKind.warning:
        return (p.warning, Icons.warning_amber);
      case AppBannerKind.error:
        return (p.error, Icons.error_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final (Color color, IconData defaultIcon) = _style(p);
    final String? actionLabel = this.actionLabel;
    final VoidCallback? onAction = this.onAction;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.badgeTint),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon ?? defaultIcon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(color: p.textPrimary),
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
