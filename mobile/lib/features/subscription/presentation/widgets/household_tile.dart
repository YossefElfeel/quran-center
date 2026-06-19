import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_status_badge.dart';
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
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final bool paidThisMonth = household.status == SubscriptionStatus.active;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    household.name,
                    style: AppTextStyles.titleMd.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppStatusBadge(
                  label: household.status.labelAr,
                  kind: _kind(household.status),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_left, color: p.textSecondary),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Text(
                  l.subsMonthlyAmount(
                    arabicNumber(household.monthlyAmount.round()),
                  ),
                  style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
                ),
                const Spacer(),
                if (paidThisMonth)
                  Text(
                    l.subsPaidThisMonth,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: p.success,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  AppButton(
                    label: l.subsRecordPayment,
                    icon: Icons.payments,
                    onPressed: onRecordPayment,
                    expanded: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppStatusKind _kind(SubscriptionStatus status) => switch (status) {
    SubscriptionStatus.active => AppStatusKind.success,
    SubscriptionStatus.grace => AppStatusKind.warning,
    SubscriptionStatus.overdue => AppStatusKind.error,
    SubscriptionStatus.inactive => AppStatusKind.neutral,
  };
}
