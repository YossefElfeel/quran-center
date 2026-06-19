import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../domain/portion.dart';

/// شريط المراجعة المطلوبة النهارده (من خطة الحصة السابقة) — تذكير للمعلّم.
/// التسميع على المراجعة بيتعمل من شيت التسميع (مفتاح حفظ/مراجعة).
class RequiredRevisionBanner extends StatelessWidget {
  const RequiredRevisionBanner({required this.revision, super.key});

  final Portion revision;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: p.accent.withValues(alpha: AppOpacity.badgeTint),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(Icons.replay, color: p.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.sesRequiredRevisionToday,
                    style: AppTextStyles.labelSm.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  Text(
                    revision.name,
                    style: AppTextStyles.titleMd.copyWith(color: p.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
