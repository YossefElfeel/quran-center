/// طالب مؤهّل لشهادة إتمام (zero-debt) — لشاشة الإصدار.
class EligibleStudent {
  const EligibleStudent({required this.id, required this.name});

  factory EligibleStudent.fromMap(Map<String, dynamic> map) => EligibleStudent(
    id: map['id'] as String,
    name: map['full_name'] as String,
  );

  final String id;
  final String name;
}
