/// طلب عذر غياب مُعلّق في طابور المشرف (مع اسم الطالب والحلقة).
class PendingExcuse {
  const PendingExcuse({
    required this.id,
    required this.enrollmentId,
    required this.studentName,
    required this.circleName,
    required this.status,
    required this.createdAt,
    this.sessionId,
    this.reason,
    this.decidedAt,
  });

  factory PendingExcuse.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? enrollment =
        map['enrollment'] as Map<String, dynamic>?;
    final Map<String, dynamic>? student =
        enrollment?['student'] as Map<String, dynamic>?;
    final Map<String, dynamic>? circle =
        enrollment?['circle'] as Map<String, dynamic>?;
    return PendingExcuse(
      id: map['id'] as String,
      enrollmentId: map['enrollment_id'] as String,
      sessionId: map['session_id'] as String?,
      studentName: (student?['full_name'] as String?) ?? 'الطالب',
      circleName: (circle?['name'] as String?) ?? 'الحلقة',
      reason: map['reason'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      decidedAt: map['decided_at'] == null
          ? null
          : DateTime.parse(map['decided_at'] as String),
    );
  }

  final String id;
  final String enrollmentId;
  final String? sessionId;
  final String studentName;
  final String circleName;
  final String? reason;
  final String status;
  final DateTime createdAt;
  final DateTime? decidedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  PendingExcuse copyWith({String? status, DateTime? decidedAt}) =>
      PendingExcuse(
        id: id,
        enrollmentId: enrollmentId,
        studentName: studentName,
        circleName: circleName,
        status: status ?? this.status,
        createdAt: createdAt,
        sessionId: sessionId,
        reason: reason,
        decidedAt: decidedAt ?? this.decidedAt,
      );
}
