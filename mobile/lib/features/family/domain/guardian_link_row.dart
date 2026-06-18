/// صف ربط: ولي أمر ↔ طفل (للعرض).
class GuardianLinkRow {
  const GuardianLinkRow({
    required this.guardianName,
    required this.childName,
    required this.relation,
  });

  factory GuardianLinkRow.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? g = map['guardian'] as Map<String, dynamic>?;
    final Map<String, dynamic>? s = map['student'] as Map<String, dynamic>?;
    return GuardianLinkRow(
      guardianName: (g?['full_name'] as String?) ?? 'ولي أمر',
      childName: (s?['full_name'] as String?) ?? 'طفل',
      relation: map['relation'] as String,
    );
  }

  final String guardianName;
  final String childName;
  final String relation;

  String get relationAr => switch (relation) {
    'father' => 'أب',
    'mother' => 'أم',
    _ => 'ولي أمر',
  };
}
