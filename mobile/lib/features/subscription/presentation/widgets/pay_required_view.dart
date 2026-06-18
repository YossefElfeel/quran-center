import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';

/// "اشتراكك مش نشط" — بتظهر لولي الأمر المتأخّر بدل المحتوى (الدفع كاش في الدار).
class PayRequiredView extends StatelessWidget {
  const PayRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lock_outline, size: 72, color: AppColors.accent),
          SizedBox(height: AppSpacing.lg),
          Text(
            'اشتراكك مش نشط',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'لازم تدفع اشتراك الشهر كاش في الدار عشان تتابع بيانات ابنك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
