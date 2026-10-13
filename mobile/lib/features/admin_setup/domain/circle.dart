/// حالة الحلقة.
enum CircleStatus {
  forming,
  active,
  graduated;

  String get dbValue => switch (this) {
    CircleStatus.forming => 'forming',
    CircleStatus.active => 'active',
    CircleStatus.graduated => 'graduated',
  };

  static CircleStatus fromDb(String value) => switch (value) {
    'active' => CircleStatus.active,
    'graduated' => CircleStatus.graduated,
    _ => CircleStatus.forming,
  };
}

/// حلقة (دُفعة) داخل مستوى. `teacherName` بيتعبّى من join مع person،
/// و`activeStudentCount` من `enrollment(count)` (مفلتر على النشطين) لو اتطلب.
class Circle {
  const Circle({
    required this.id,
    required this.levelId,
    required this.name,
    required this.maxSize,
    required this.status,
    this.teacherId,
    this.teacherName,
    this.activeStudentCount,
  });

  final String id;
  final String levelId;
  final String name;
  final int maxSize;
  final CircleStatus status;
  final String? teacherId;
  final String? teacherName;

  /// عدد الطلبة النشطين (null = الاستعلام ماطلبهوش).
  final int? activeStudentCount;

  factory Circle.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? teacher =
        map['teacher'] as Map<String, dynamic>?;
    final List<dynamic>? enrollment = map['enrollment'] as List<dynamic>?;
    final Object? rawCount = enrollment == null
        ? null
        : enrollment.isEmpty
        ? 0
        : (enrollment.first as Map<String, dynamic>)['count'];
    return Circle(
      id: map['id'] as String,
      levelId: map['level_id'] as String,
      name: map['name'] as String,
      maxSize: map['max_size'] as int,
      status: CircleStatus.fromDb(map['status'] as String),
      teacherId: map['teacher_id'] as String?,
      teacherName: teacher?['full_name'] as String?,
      activeStudentCount: rawCount is num ? rawCount.toInt() : null,
    );
  }
}
