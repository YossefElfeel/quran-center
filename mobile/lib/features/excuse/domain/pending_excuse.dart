/// طلب عذر غياب في طابور المشرف (مع اسم الطالب والحلقة ويوم الغياب ومين طلبه).
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
    this.absenceDate,
    this.requesterName,
  });

  factory PendingExcuse.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? enrollment =
        map['enrollment'] as Map<String, dynamic>?;
    final Map<String, dynamic>? student =
        enrollment?['student'] as Map<String, dynamic>?;
    final Map<String, dynamic>? circle =
        enrollment?['circle'] as Map<String, dynamic>?;
    final Map<String, dynamic>? teacher =
        circle?['teacher'] as Map<String, dynamic>?;
    final Map<String, dynamic>? session =
        map['session'] as Map<String, dynamic>?;
    final String? sessionDate = session?['session_date'] as String?;
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
      absenceDate: sessionDate == null ? null : DateTime.parse(sessionDate),
      requesterName: teacher?['full_name'] as String?,
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

  /// يوم الحصة اللي الطالب غاب فيها (`circle_session.session_date`).
  final DateTime? absenceDate;

  /// مين طلب العذر — معلّم الحلقة (الجدول مفيهوش `requested_by`؛ الـ RLS
  /// بيسمح بالإنشاء لمعلّم الحلقة أو الأدمن).
  final String? requesterName;

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
        absenceDate: absenceDate,
        requesterName: requesterName,
      );
}
