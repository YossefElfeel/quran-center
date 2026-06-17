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

  static AttendanceStatus fromDb(String value) => switch (value) {
        'absent' => AttendanceStatus.absent,
        'absent_excused' => AttendanceStatus.absentExcused,
        'late' => AttendanceStatus.late,
        _ => AttendanceStatus.present,
      };
}
