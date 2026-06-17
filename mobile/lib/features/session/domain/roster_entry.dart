import '../../enrollment/domain/gender.dart';
import 'attendance_status.dart';

/// صف في روستر الحصة (طالب + حالته).
class RosterEntry {
  const RosterEntry({
    required this.enrollmentId,
    required this.studentName,
    required this.attendance,
    this.gender,
  });

  final String enrollmentId;
  final String studentName;
  final AttendanceStatus attendance;
  final Gender? gender;

  RosterEntry copyWith({AttendanceStatus? attendance}) => RosterEntry(
    enrollmentId: enrollmentId,
    studentName: studentName,
    attendance: attendance ?? this.attendance,
    gender: gender,
  );
}

/// حالة "حصة النهارده" لحلقة: الحصة المفتوحة (لو فيه) + الروستر.
class TodaySession {
  const TodaySession({required this.roster, this.sessionId});

  final String? sessionId;
  final List<RosterEntry> roster;

  bool get isOpen => sessionId != null;
}
