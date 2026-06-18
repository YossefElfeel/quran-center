import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';

/// شريط ملخّص المقطع الحالي: عدّوا كام / عليهم دَيْن كام.
class DebtStrip extends StatelessWidget {
  const DebtStrip({
    required this.passedCount,
    required this.debtCount,
    required this.total,
    super.key,
  });

  final int passedCount;
  final int debtCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          _Pill(
            label: l.sesDebtPassed,
            value: '${arabicNumber(passedCount)}/${arabicNumber(total)}',
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Pill(
            label: l.sesDebtOwed,
            value: arabicNumber(debtCount),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
