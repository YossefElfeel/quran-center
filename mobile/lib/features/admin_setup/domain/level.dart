/// مستوى داخل منهج (entity).
class Level {
  const Level({
    required this.id,
    required this.curriculumId,
    required this.ord,
    required this.name,
  });

  final String id;
  final String curriculumId;
  final int ord;
  final String name;

  factory Level.fromMap(Map<String, dynamic> map) => Level(
    id: map['id'] as String,
    curriculumId: map['curriculum_id'] as String,
    ord: map['ord'] as int,
    name: map['name'] as String,
  );
}
