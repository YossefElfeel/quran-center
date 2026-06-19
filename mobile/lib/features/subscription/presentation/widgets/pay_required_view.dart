import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';

/// "اشتراكك مش نشط" — بتظهر لولي الأمر المتأخّر بدل المحتوى (الدفع كاش في الدار).
class PayRequiredView extends StatelessWidget {
  const PayRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lock_outline, size: 72, color: context.palette.accent),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.subsInactiveTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.subsInactiveBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
