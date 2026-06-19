import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/pending_excuse.dart';

/// بلاطة طلب عذر — اسم الطالب والحلقة والسبب + موافقة/رفض.
class ExcuseDecisionTile extends StatelessWidget {
  const ExcuseDecisionTile({
    required this.excuse,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final PendingExcuse excuse;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final String? reason = excuse.reason;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              excuse.studentName,
              style: AppTextStyles.titleMd.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              excuse.circleName,
              style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
            ),
            if (reason != null && reason.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                reason,
                style: AppTextStyles.bodyMd.copyWith(color: p.textPrimary),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: l.excReject,
                    icon: Icons.close,
                    onPressed: onReject,
                    variant: AppButtonVariant.outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: l.excApprove,
                    icon: Icons.check,
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
