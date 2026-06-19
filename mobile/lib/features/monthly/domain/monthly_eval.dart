/// صف تقييم شهري لطالب في قائمة المعلّم (status=null يعني لسه ماتعملش).
class MonthlyEvalStudent {
  const MonthlyEvalStudent({
    required this.studentPersonId,
    required this.studentName,
    this.status,
    this.summary,
    this.behavior,
  });

  final String studentPersonId;
  final String studentName;
  final String? status;
  final String? summary;
  final String? behavior;

  bool get isApproved => status == 'approved';
  bool get isSubmitted => status == 'submitted';
}

/// تقييم شهري في طابور اعتماد المشرف.
class PendingMonthlyEval {
  const PendingMonthlyEval({
    required this.id,
    required this.studentName,
    required this.month,
    this.summary,
    this.behavior,
  });

  factory PendingMonthlyEval.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? s = map['student'] as Map<String, dynamic>?;
    return PendingMonthlyEval(
      id: map['id'] as String,
      studentName: (s?['full_name'] as String?) ?? 'طالب',
      month: DateTime.parse(map['month'] as String),
      summary: map['summary'] as String?,
      behavior: map['behavior'] as String?,
    );
  }

  final String id;
  final String studentName;
  final DateTime month;
  final String? summary;
  final String? behavior;
}
