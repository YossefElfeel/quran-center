/// طالب متعثّر: عليه دَيْن على مقطع وفشل فيه مرّات كتير (محتاج انتباه).
class StrugglingStudent {
  const StrugglingStudent({
    required this.studentName,
    required this.portionName,
    required this.attempts,
  });

  factory StrugglingStudent.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> student = map['student'] as Map<String, dynamic>;
    final Map<String, dynamic> portion = map['portion'] as Map<String, dynamic>;
    return StrugglingStudent(
      studentName: student['full_name'] as String,
      portionName: portion['name'] as String,
      attempts: (map['attempts_count'] as num).toInt(),
    );
  }

  final String studentName;
  final String portionName;
  final int attempts;
}
