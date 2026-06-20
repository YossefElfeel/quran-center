import '../../../core/logging/logger.dart';

/// حالة حضور الطالب في الحصة.
enum AttendanceStatus {
  present,
  absent,
  absentExcused,
  late;

  String get dbValue => switch (this) {
    AttendanceStatus.present => 'present',
    AttendanceStatus.absent => 'absent',
    AttendanceStatus.absentExcused => 'absent_excused',
    AttendanceStatus.late => 'late',
  };

  String get labelAr => switch (this) {
    AttendanceStatus.present => 'حاضر',
    AttendanceStatus.absent => 'غايب',
    AttendanceStatus.absentExcused => 'غايب بعذر',
    AttendanceStatus.late => 'متأخّر',
  };

  static AttendanceStatus fromDb(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'absent_excused':
        return AttendanceStatus.absentExcused;
      case 'late':
        return AttendanceStatus.late;
    }
    AppLog.warn('Unknown attendance status from server: $value');
    return AttendanceStatus.present;
  }
}
