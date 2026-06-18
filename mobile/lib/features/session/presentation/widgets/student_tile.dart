import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../enrollment/domain/gender.dart';
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
    this.onRequestExcuse,
    super.key,
  });

  final RosterEntry entry;
  final bool canRecordTasmee;
  final ValueChanged<AttendanceStatus> onAttendanceChanged;
  final VoidCallback onTasmee;

  /// متاح لو الطالب غايب — يطلب عذر للمشرف (null = ماينفعش).
  final VoidCallback? onRequestExcuse;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(
                entry.gender == Gender.female ? Icons.girl : Icons.boy,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _LedgerBadge(state: entry.ledgerState),
                  if (onRequestExcuse != null)
                    TextButton(
                      onPressed: onRequestExcuse,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'طلب عذر',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            _AttendanceDropdown(
              value: entry.attendance,
              onChanged: onAttendanceChanged,
            ),
            if (canRecordTasmee) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              IconButton.filled(
                tooltip: 'تسميع',
                icon: const Icon(Icons.record_voice_over),
                onPressed: onTasmee,
              ),
            ],
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
    final (String label, Color color) = switch (state) {
      LedgerState.passed => ('عدّى', AppColors.success),
      LedgerState.failedRetry => ('عليه دَيْن', AppColors.error),
      _ => ('لسه', AppColors.textSecondary),
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
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
              child: Text(s.labelAr),
            ),
          )
          .toList(),
      onChanged: (AttendanceStatus? v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
