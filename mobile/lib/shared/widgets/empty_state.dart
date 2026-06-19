import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';

/// حالة فاضية موحّدة (قائمة بدون عناصر / لسه مفيش بيانات) — مع إجراء اختياري.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String? title = this.title;
    final Widget? action = this.action;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: AppOpacity.hover),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: p.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...<Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLg.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg.copyWith(color: p.textSecondary),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
