import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../enrollment/domain/gender.dart';
import '../../domain/attendance_status.dart';
import '../../domain/roster_entry.dart';

/// بلاطة طالب في الحصة: الاسم + اختيار حالة الحضور.
class AttendanceTile extends StatelessWidget {
  const AttendanceTile({
    required this.entry,
    required this.onChanged,
    super.key,
  });

  final RosterEntry entry;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Icon(entry.gender == Gender.female ? Icons.girl : Icons.boy),
        ),
        title: Text(entry.studentName),
        trailing: DropdownButton<AttendanceStatus>(
          value: entry.attendance,
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
        ),
      ),
    );
  }
}
