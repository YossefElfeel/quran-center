import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';
import 'app_card.dart';

/// عنصر قائمة موحّد (يستبدل نمط `Card(child: ListTile(...))` المتكرّر).
/// أيقونة بادئة في دائرة ملوّنة + عنوان + سطر فرعي + لاحقة/شيفرون.
class AppListCard extends StatelessWidget {
  const AppListCard({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leading,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color icColor = iconColor ?? p.primary;
    final String? subtitle = this.subtitle;

    final Widget? lead =
        leading ??
        (leadingIcon != null
            ? Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: icColor.withValues(alpha: AppOpacity.badgeTint),
                  shape: BoxShape.circle,
                ),
                child: Icon(leadingIcon, color: icColor, size: 22),
              )
            : null);

    final Widget? trail =
        trailing ??
        (onTap != null
            ? Icon(Icons.chevron_left, color: p.textSecondary)
            : null);

    return Padding(
      padding: margin,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: MergeSemantics(
          child: Row(
            children: <Widget>[
              if (lead != null) ...<Widget>[
                lead,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.titleMd.copyWith(
                        color: p.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: p.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trail != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                trail,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
