import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';

/// حوار تأكيد بشري لنقل المجموعة — بيرجّع true لو المعلّم أكّد.
Future<bool?> showAdvanceConfirmationDialog(
  BuildContext context, {
  required int passedCount,
  required int activeAtOpen,
}) {
  final AppL10n l = AppL10n.of(context);
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l.sesAdvanceConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.sesAdvanceConfirmCount(
              arabicNumber(passedCount),
              arabicNumber(activeAtOpen),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.sesAdvanceConfirmWarning,
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.sesCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.sesAdvance),
        ),
      ],
    ),
  );
}
