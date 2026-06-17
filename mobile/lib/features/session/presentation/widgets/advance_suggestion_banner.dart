import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_numerals.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            const Icon(Icons.trending_up, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'المجموعة جاهزة تنتقل',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'عدّى ${arabicNumber(passedCount)} من '
                    '${arabicNumber(activeAtOpen)} — أكتر من النص',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onAdvance,
              child: const Text('انقل المجموعة'),
            ),
          ],
        ),
      ),
    );
  }
}
