import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/presentation/domain_labels.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../progress_engine/domain/ledger_state.dart';
import '../../domain/attendance_status.dart';
import '../../domain/roster_entry.dart';

/// بلاطة طالب في الحصة: الحضور + حالة الدَيْن + زرّ التسميع.
class StudentTile extends StatelessWidget {
  const StudentTile({
    required this.entry,
    required this.canRecordTasmee,
    required this.onAttendanceChanged,
    required this.onTasmee,
    this.onNote,
    this.excuseRequested = false,
    this.onRequestExcuse,
    super.key,
  });

  final RosterEntry entry;
  final bool canRecordTasmee;
  final ValueChanged<AttendanceStatus> onAttendanceChanged;
  final VoidCallback onTasmee;

  /// تسجيل ملاحظة سلوك للطالب (null = مخفي).
  final VoidCallback? onNote;
  final bool excuseRequested;

  /// متاح لو الطالب غايب — يطلب عذر للمشرف (null = ماينفعش).
  final VoidCallback? onRequestExcuse;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppAvatar(name: entry.studentName, radius: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.studentName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _LedgerBadge(state: entry.ledgerState),
            if (excuseRequested) const Text('طلب متبعت'),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _AttendanceDropdown(
                  value: entry.attendance,
                  onChanged: onAttendanceChanged,
                ),
                if (onRequestExcuse != null)
                  TextButton(
                    onPressed: onRequestExcuse,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(l.sesRequestExcuse),
                  ),
                if (onNote != null)
                  IconButton(
                    tooltip: l.sesBehavioralNoteTooltip,
                    icon: const Icon(AppIcons.note),
                    onPressed: onNote,
                  ),
                if (canRecordTasmee)
                  IconButton.filled(
                    tooltip: l.sesTasmeeTooltip,
                    style: IconButton.styleFrom(
                      foregroundColor: palette.onPrimary,
                    ),
                    icon: Icon(AppIcons.tasmee, color: palette.onPrimary),
                    onPressed: onTasmee,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerBadge extends StatelessWidget {
  const _LedgerBadge({required this.state});

  final LedgerState? state;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final (String label, AppStatusKind kind) = switch (state) {
      LedgerState.passed => (l.sesLedgerPassed, AppStatusKind.success),
      LedgerState.failedRetry => (l.sesLedgerOwed, AppStatusKind.error),
      _ => (l.sesLedgerPending, AppStatusKind.neutral),
    };
    return AppStatusBadge(label: label, kind: kind);
  }
}

class _AttendanceDropdown extends StatelessWidget {
  const _AttendanceDropdown({required this.value, required this.onChanged});

  final AttendanceStatus value;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AttendanceStatus>(
      value: value,
      underline: const SizedBox.shrink(),
      items: AttendanceStatus.values
          .map(
            (AttendanceStatus s) => DropdownMenuItem<AttendanceStatus>(
              value: s,
              child: Text(s.label(AppL10n.of(context))),
            ),
          )
          .toList(),
      onChanged: (AttendanceStatus? v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
