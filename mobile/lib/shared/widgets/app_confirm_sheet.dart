import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'app_modal_sheet.dart';

/// يفتح bottom sheet تأكيد موحّد (إجراء مدمّر افتراضيًا) ويرجّع `true` لو أكّد
/// المستخدم و`false` لو ألغى أو سحب الـ sheet.
///
/// - [destructive] = true ⇒ أيقونة/زرّ بلون الخطأ (أحمر).
/// - زرّ التأكيد المدمّر بيستعمل [FilledButton] بخلفية `p.error` عشان
///   [AppButton] مفيهوش لون مخصّص — بس بيرث نفس الارتفاع/الشكل من الثيم.
Future<bool> showAppConfirmSheet({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String? message,
  String? cancelLabel,
  bool destructive = true,
  IconData? icon,
}) async {
  final bool? result = await showAppModalSheet<bool>(
    context: context,
    builder: (BuildContext context) {
      final AppPalette p = context.palette;
      final Color accent = destructive ? p.error : p.primary;
      final IconData? icon0 = icon;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (icon0 != null) ...<Widget>[
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: AppOpacity.badgeTint),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon0, color: accent, size: 28),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLg.copyWith(color: p.textPrimary),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (destructive)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.error,
                foregroundColor: p.onPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel, overflow: TextOverflow.ellipsis),
            )
          else
            AppButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: cancelLabel ?? 'إلغاء',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
