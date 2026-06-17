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

  String get labelAr => switch (this) {
        CircleStatus.forming => 'بتتجمّع',
        CircleStatus.active => 'شغّالة',
        CircleStatus.graduated => 'اتخرّجت',
      };

  static CircleStatus fromDb(String value) => switch (value) {
        'active' => CircleStatus.active,
        'graduated' => CircleStatus.graduated,
        _ => CircleStatus.forming,
      };
}

/// حلقة (دُفعة) داخل مستوى. `teacherName` بيتعبّى من join مع person.
class Circle {
  const Circle({
    required this.id,
    required this.levelId,
    required this.name,
    required this.maxSize,
    required this.status,
    this.teacherId,
    this.teacherName,
  });

  final String id;
  final String levelId;
  final String name;
  final int maxSize;
  final CircleStatus status;
  final String? teacherId;
  final String? teacherName;

  factory Circle.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? teacher = map['teacher'] as Map<String, dynamic>?;
    return Circle(
      id: map['id'] as String,
      levelId: map['level_id'] as String,
      name: map['name'] as String,
      maxSize: map['max_size'] as int,
      status: CircleStatus.fromDb(map['status'] as String),
      teacherId: map['teacher_id'] as String?,
      teacherName: teacher?['full_name'] as String?,
    );
  }
}
