import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
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
    final String? reason = excuse.reason;
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              excuse.studentName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              excuse.circleName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (reason != null && reason.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(reason),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: Text(
                      l.excReject,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: Text(l.excApprove),
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
