import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';

/// لوحة اختيار درجة من ٠ لـ ١٠ (خلايا لمس كبيرة، تلوين حسب حد النجاح).
class ScorePad extends StatelessWidget {
  const ScorePad({
    required this.selected,
    required this.threshold,
    required this.onSelected,
    super.key,
  });

  final int? selected;
  final int threshold;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (int i = 0; i <= 10; i++)
          _ScoreCell(
            value: i,
            isSelected: selected == i,
            isPass: i >= threshold,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.value,
    required this.isSelected,
    required this.isPass,
    required this.onTap,
  });

  final int value;
  final bool isSelected;
  final bool isPass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color base = isPass ? AppColors.success : AppColors.error;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: AppSizes.minTouch,
        height: AppSizes.minTouch,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? base : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: base, width: 1.5),
        ),
        child: Text(
          arabicNumber(value),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : base,
          ),
        ),
      ),
    );
  }
}
