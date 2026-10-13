import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_confirm_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../domain/pending_excuse.dart';

/// بلاطة طلب عذر — اسم الطالب والحلقة والسبب + موافقة/رفض.
class ExcuseDecisionTile extends StatefulWidget {
  const ExcuseDecisionTile({
    required this.excuse,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
    super.key,
  });

  final PendingExcuse excuse;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final VoidCallback onTap;

  @override
  State<ExcuseDecisionTile> createState() => _ExcuseDecisionTileState();
}

class _ExcuseDecisionTileState extends State<ExcuseDecisionTile> {
  bool _busy = false;

  Future<void> _decide(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await showAppConfirmSheet(
        context: context,
        title: 'تأكيد قرار العذر',
        confirmLabel: 'حفظ القرار',
        destructive: false,
      )) {
        return;
      }
      await action();
      if (mounted) AppSnackbar.success(context, 'قرار العذر اتحفظ');
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, AppL10n.of(context).genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final PendingExcuse excuse = widget.excuse;
    final String? reason = excuse.reason;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: AppCard(
        onTap: widget.onTap,
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
            if (excuse.isPending)
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton(
                      label: l.excReject,
                      icon: Icons.close,
                      onPressed: _busy ? null : () => _decide(widget.onReject),
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: l.excApprove,
                      icon: Icons.check,
                      onPressed: _busy ? null : () => _decide(widget.onApprove),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppStatusBadge(
                  label: excuse.isApproved ? l.excApproved : l.excRejected,
                  kind: excuse.isApproved
                      ? AppStatusKind.success
                      : AppStatusKind.error,
                  icon: excuse.isApproved
                      ? AppIcons.approved
                      : AppIcons.rejected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
