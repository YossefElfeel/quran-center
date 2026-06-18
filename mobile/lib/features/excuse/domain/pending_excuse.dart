/// طلب عذر غياب مُعلّق في طابور المشرف (مع اسم الطالب والحلقة).
class PendingExcuse {
  const PendingExcuse({
    required this.id,
    required this.enrollmentId,
    required this.studentName,
    required this.circleName,
    this.sessionId,
    this.reason,
  });

  factory PendingExcuse.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> enrollment =
        map['enrollment'] as Map<String, dynamic>;
    final Map<String, dynamic> student =
        enrollment['student'] as Map<String, dynamic>;
    final Map<String, dynamic>? circle =
        enrollment['circle'] as Map<String, dynamic>?;
    return PendingExcuse(
      id: map['id'] as String,
      enrollmentId: map['enrollment_id'] as String,
      sessionId: map['session_id'] as String?,
      studentName: student['full_name'] as String,
      circleName: (circle?['name'] as String?) ?? 'الحلقة',
      reason: map['reason'] as String?,
    );
  }

  final String id;
  final String enrollmentId;
  final String? sessionId;
  final String studentName;
  final String circleName;
  final String? reason;
}
