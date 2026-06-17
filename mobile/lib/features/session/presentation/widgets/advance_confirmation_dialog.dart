import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';

/// حوار تأكيد بشري لنقل المجموعة — بيرجّع true لو المعلّم أكّد.
Future<bool?> showAdvanceConfirmationDialog(
  BuildContext context, {
  required int passedCount,
  required int activeAtOpen,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('تأكيد نقل المجموعة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'عدّى ${arabicNumber(passedCount)} من '
            '${arabicNumber(activeAtOpen)} طالب على المقطع الحالي.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'اللي ماعدّوش هيفضل عليهم دَيْن على المقطع ده. '
            'تنقل المجموعة لمقطع جديد؟',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('انقل'),
        ),
      ],
    ),
  );
}
