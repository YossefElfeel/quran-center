/// تقييم محفّظ (لعرض المدير/المشرف) — المعلّم مايشوفوش (RLS).
class TeacherRatingRow {
  const TeacherRatingRow({
    required this.id,
    required this.teacherName,
    required this.stars,
    required this.hidden,
    this.comment,
  });

  factory TeacherRatingRow.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? t = map['teacher'] as Map<String, dynamic>?;
    return TeacherRatingRow(
      id: map['id'] as String,
      teacherName: (t?['full_name'] as String?) ?? 'المحفّظ',
      stars: (map['stars'] as num).toInt(),
      hidden: map['hidden_by_manager'] as bool? ?? false,
      comment: map['comment'] as String?,
    );
  }

  final String id;
  final String teacherName;
  final int stars;
  final bool hidden;
  final String? comment;
}
