import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

/// عرض خطأ موحّد بصياغة عربية + زر إعادة محاولة اختياري.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.message,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final VoidCallback? onRetry = this.onRetry;
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
                color: p.error.withValues(alpha: AppOpacity.badgeTint),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: p.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: retryLabel ?? l.retry,
                icon: Icons.refresh,
                onPressed: onRetry,
                expanded: false,
                variant: AppButtonVariant.tonal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
