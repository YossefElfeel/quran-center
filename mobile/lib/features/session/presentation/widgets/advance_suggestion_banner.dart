import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';

/// شريط بيظهر لما المجموعة تعدّي >٥٠٪ المقطع الحالي — يقترح الانتقال (بتأكيد).
class AdvanceSuggestionBanner extends StatelessWidget {
  const AdvanceSuggestionBanner({
    required this.passedCount,
    required this.activeAtOpen,
    required this.onAdvance,
    super.key,
  });

  final int passedCount;
  final int activeAtOpen;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: p.success.withValues(alpha: AppOpacity.badgeTint),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(Icons.trending_up, color: p.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.sesAdvanceReady,
                    style: AppTextStyles.titleMd.copyWith(color: p.textPrimary),
                  ),
                  Text(
                    l.sesAdvanceReadySubtitle(
                      arabicNumber(passedCount),
                      arabicNumber(activeAtOpen),
                    ),
                    style: AppTextStyles.labelSm.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onAdvance, child: Text(l.sesAdvanceGroup)),
          ],
        ),
      ),
    );
  }
}
