import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';

/// نوع البادج (بيحدّد اللون).
enum AppStatusKind { success, warning, error, info, neutral, primary }

/// بادج حالة موحّد (pill) — يستبدل شارات الحالة المنسوخة في التايلات.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.kind = AppStatusKind.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final AppStatusKind kind;
  final IconData? icon;

  Color _color(AppPalette p) {
    switch (kind) {
      case AppStatusKind.success:
        return p.success;
      case AppStatusKind.warning:
        return p.warning;
      case AppStatusKind.error:
        return p.error;
      case AppStatusKind.info:
        return p.info;
      case AppStatusKind.primary:
        return p.primary;
      case AppStatusKind.neutral:
        return p.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color color = _color(p);
    final IconData? icon = this.icon;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.badgeTint),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
