import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../enrollment/domain/gender.dart';
import '../../domain/waiting_applicant.dart';

/// بلاطة متقدّم في قائمة الانتظار + إجراءين: تحديد المستوى / الإسناد لحلقة.
class ApplicantTile extends StatelessWidget {
  const ApplicantTile({
    required this.applicant,
    required this.onPlacement,
    required this.onEnroll,
    super.key,
  });

  final WaitingApplicant applicant;
  final VoidCallback onPlacement;
  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: p.primary,
                  foregroundColor: p.onPrimary,
                  child: Icon(
                    applicant.gender == Gender.female ? Icons.girl : Icons.boy,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        applicant.name,
                        style: AppTextStyles.titleMd.copyWith(
                          color: p.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.itkTargetLevelLabel(applicant.levelName),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: p.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: l.itkSetLevel,
                    icon: Icons.assignment_turned_in,
                    onPressed: onPlacement,
                    variant: AppButtonVariant.outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: l.itkAssignToCircle,
                    icon: Icons.how_to_reg,
                    onPressed: onEnroll,
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
