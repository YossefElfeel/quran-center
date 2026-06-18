import 'package:flutter/material.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../domain/household_summary.dart';
import '../../domain/subscription_status.dart';

/// بلاطة أسرة: الاسم + الحالة + زرّ دفعة؛ ولمسها تفتح أفراد الأسرة.
class HouseholdTile extends StatelessWidget {
  const HouseholdTile({
    required this.household,
    required this.onRecordPayment,
    required this.onTap,
    super.key,
  });

  final HouseholdSummary household;
  final VoidCallback onRecordPayment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool paidThisMonth = household.status == SubscriptionStatus.active;
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      household.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: household.status),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_left,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Text(
                    'الاشتراك الشهري: '
                    '${arabicNumber(household.monthlyAmount.round())} ج',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (paidThisMonth)
                    const Text(
                      'مدفوع الشهر ده ✓',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: onRecordPayment,
                      icon: const Icon(Icons.payments, size: 18),
                      label: const Text('سجّل دفعة'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      SubscriptionStatus.active => AppColors.success,
      SubscriptionStatus.grace => AppColors.accent,
      SubscriptionStatus.overdue => AppColors.error,
      SubscriptionStatus.inactive => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
