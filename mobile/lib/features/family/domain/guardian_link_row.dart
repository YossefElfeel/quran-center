/// صف ربط: ولي أمر ↔ طفل (للعرض).
class GuardianLinkRow {
  const GuardianLinkRow({
    required this.guardianName,
    required this.childName,
    required this.relation,
    this.guardianId = '',
    this.studentId = '',
    this.hasLogin = false,
    this.householdId,
    this.householdName,
    this.subscriptionActive = false,
    this.childrenCount = 0,
  });

  factory GuardianLinkRow.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? g = map['guardian'] as Map<String, dynamic>?;
    final Map<String, dynamic>? s = map['student'] as Map<String, dynamic>?;
    return GuardianLinkRow(
      guardianName:
          map['guardian_name'] as String? ??
          (g?['full_name'] as String?) ??
          'ولي أمر',
      guardianId: map['guardian_id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      hasLogin: map['has_login'] as bool? ?? false,
      householdId: map['household_id'] as String?,
      householdName: map['household_name'] as String?,
      subscriptionActive: map['subscription_active'] as bool? ?? false,
      childrenCount: (map['children_count'] as num?)?.toInt() ?? 0,
      childName:
          map['child_name'] as String? ?? (s?['full_name'] as String?) ?? 'طفل',
      relation: map['relation'] as String,
    );
  }

  final String guardianName;
  final String childName;
  final String relation;
  final String guardianId, studentId;
  final bool hasLogin, subscriptionActive;
  final String? householdId, householdName;
  final int childrenCount;

  String get relationAr => switch (relation) {
    'father' => 'أب',
    'mother' => 'أم',
    _ => 'ولي أمر',
  };
}
