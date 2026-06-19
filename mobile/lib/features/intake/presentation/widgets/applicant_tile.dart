import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Icon(
                  applicant.gender == Gender.female ? Icons.girl : Icons.boy,
                ),
              ),
              title: Text(applicant.name),
              subtitle: Text(l.itkTargetLevelLabel(applicant.levelName)),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPlacement,
                    icon: const Icon(Icons.assignment_turned_in),
                    label: Text(l.itkSetLevel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEnroll,
                    icon: const Icon(Icons.how_to_reg),
                    label: Text(l.itkAssignToCircle),
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
