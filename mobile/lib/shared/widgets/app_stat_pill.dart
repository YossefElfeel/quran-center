import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'app_card.dart';

/// بطاقة إحصائية للداشبورد — رقم بعدّاد متحرّك + تسمية + أيقونة، قابلة للنقر.
class AppStatPill extends StatelessWidget {
  const AppStatPill({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    super.key,
  });

  final int value;
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color color = this.color ?? p.primary;
    final IconData? icon = this.icon;
    final bool noMotion = reduceMotion(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: AppOpacity.badgeTint),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: noMotion ? Duration.zero : AppDurations.xl,
                  curve: AppCurves.emphasized,
                  builder: (BuildContext context, int v, Widget? _) => Text(
                    '$v',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLg.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
