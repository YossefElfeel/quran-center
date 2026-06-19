/// متفوّق شهر لحلقة (للوحة الشرف).
class TopStudentRow {
  const TopStudentRow({
    required this.studentName,
    required this.circleName,
    required this.month,
    this.reason,
  });

  factory TopStudentRow.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? c = map['circle'] as Map<String, dynamic>?;
    final Map<String, dynamic>? s = map['student'] as Map<String, dynamic>?;
    return TopStudentRow(
      studentName: (s?['full_name'] as String?) ?? 'طالب',
      circleName: (c?['name'] as String?) ?? 'حلقة',
      month: DateTime.parse(map['month'] as String),
      reason: map['reason'] as String?,
    );
  }

  final String studentName;
  final String circleName;
  final DateTime month;
  final String? reason;
}
