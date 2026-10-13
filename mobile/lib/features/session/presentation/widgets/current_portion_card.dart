import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/portion.dart';

/// كارت المقطع الحالي للحلقة — يعرض المقطع أو زرّ تحديده.
class CurrentPortionCard extends StatelessWidget {
  const CurrentPortionCard({
    required this.portion,
    required this.onSetPortion,
    super.key,
  });

  final Portion? portion;
  final VoidCallback onSetPortion;

  @override
  Widget build(BuildContext context) {
    final Portion? p = portion;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppCard(
        child: p == null ? _Empty(onSetPortion: onSetPortion) : _Current(p),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onSetPortion});

  final VoidCallback onSetPortion;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    // بانر معلومة + إجراء ثانوي (tonal) — "اقفل الحصة" يفضل الزرّ الأساسي
    // الوحيد في الشاشة.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.info_outline, color: p.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l.sesNoPortionYet,
                style: AppTextStyles.bodyMd.copyWith(color: p.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppButton(
            label: l.sesSetPortion,
            icon: Icons.menu_book,
            variant: AppButtonVariant.tonal,
            expanded: false,
            onPressed: onSetPortion,
          ),
        ),
      ],
    );
  }
}

class _Current extends StatelessWidget {
  const _Current(this.portion);

  final Portion portion;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Row(
      children: <Widget>[
        Icon(Icons.menu_book, color: p.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.sesCurrentPortion,
                style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
              ),
              Text(
                portion.name,
                style: AppTextStyles.titleMd.copyWith(color: p.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
