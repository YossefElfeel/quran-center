/// قيد تطوّر شهري للمعلّم (يسجّله المعلّم، يعتمده المشرف).
class TeacherDevEntry {
  const TeacherDevEntry({
    required this.id,
    required this.month,
    required this.status,
    this.progress,
    this.teacherName,
  });

  factory TeacherDevEntry.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? teacher =
        map['teacher'] as Map<String, dynamic>?;
    return TeacherDevEntry(
      id: map['id'] as String,
      month: DateTime.parse(map['month'] as String),
      status: map['status'] as String,
      progress: map['memorization_progress'] as String?,
      teacherName: teacher?['full_name'] as String?,
    );
  }

  final String id;
  final DateTime month;
  final String status;
  final String? progress;
  final String? teacherName;

  bool get isApproved => status == 'approved';
}
