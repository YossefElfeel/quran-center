import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// بطاقة موحّدة — سطح + زوايا lg + ظلّ ناعم + نقر اختياري (ripple).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.showBorder = true,
    this.showShadow = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool showBorder;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final BorderRadius radius = BorderRadius.circular(AppRadii.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow ? AppElevation.shadowSm(p.shadowColor) : null,
      ),
      child: Material(
        color: color ?? p.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: showBorder
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: p.border, width: 0.6),
                  )
                : null,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
