import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_date.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../domain/complaint.dart';

/// محتوى موحّد لتفاصيل الشكوى في شاشة صاحبها وصندوق الإدارة.
class ComplaintDetailContent extends StatelessWidget {
  const ComplaintDetailContent({
    required this.complaint,
    this.action,
    super.key,
  });

  final Complaint complaint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            AppStatusBadge(
              label: complaint.statusAr,
              kind: complaint.isAnswered
                  ? AppStatusKind.success
                  : AppStatusKind.warning,
            ),
            Text(
              l.fbkComplaintNumber(complaint.referenceNumber),
              style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.fbkSubmittedAt(arabicDateTimeLabel(complaint.createdAt)),
          style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          complaintCategoriesAr[complaint.category] ?? complaint.category,
          style: AppTextStyles.titleMd.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(
          complaint.body,
          style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
        ),
        if (complaint.isAnswered) ...<Widget>[
          const Divider(height: AppSpacing.xl),
          Text(
            l.fbkManagerResponseLabel,
            style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            complaint.managerResponse!,
            style: AppTextStyles.bodyMd.copyWith(color: p.textPrimary),
          ),
          if (complaint.respondedAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.fbkRespondedAt(arabicDateTimeLabel(complaint.respondedAt!)),
              style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
            ),
          ],
        ],
        if (action != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          action!,
        ],
      ],
    );
  }
}
