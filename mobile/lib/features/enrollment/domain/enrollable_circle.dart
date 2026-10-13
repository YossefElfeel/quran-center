/// حلقة متاحة للتسجيل (مع المنهج/المستوى وعدد الطلبة النشطين).
class EnrollableCircle {
  const EnrollableCircle({
    required this.id,
    required this.name,
    required this.activeCount,
    this.maxSize,
    this.levelName = '',
    this.curriculumName = '',
  });

  final String id;
  final String name;
  final int activeCount;

  /// null = مفيش حد أقصى متسجّل.
  final int? maxSize;
  final String levelName;
  final String curriculumName;

  bool get isFull => maxSize != null && activeCount >= maxSize!;

  /// مفتاح التجميع: المنهج ← المستوى.
  String get groupLabel {
    final List<String> parts = <String>[
      curriculumName,
      levelName,
    ].where((String p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' / ');
  }

  static EnrollableCircle fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? level = map['level'] as Map<String, dynamic>?;
    final Map<String, dynamic>? curriculum =
        level?['curriculum'] as Map<String, dynamic>?;
    final List<dynamic> count =
        map['enrollment'] as List<dynamic>? ?? const <dynamic>[];
    final Object? rawCount = count.isEmpty
        ? 0
        : (count.first as Map<String, dynamic>)['count'];
    return EnrollableCircle(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '—',
      activeCount: (rawCount as num?)?.toInt() ?? 0,
      maxSize: (map['max_size'] as num?)?.toInt(),
      levelName: (level?['name'] as String?) ?? '',
      curriculumName: (curriculum?['name'] as String?) ?? '',
    );
  }
}

/// يجمّع الحلقات حسب المنهج ← المستوى مع الحفاظ على ترتيب أول ظهور
/// (الاستعلام مرتّب بالمنهج ثم المستوى ثم الاسم).
Map<String, List<EnrollableCircle>> groupEnrollableCircles(
  Iterable<EnrollableCircle> circles,
) {
  final Map<String, List<EnrollableCircle>> groups =
      <String, List<EnrollableCircle>>{};
  for (final EnrollableCircle c in circles) {
    groups.putIfAbsent(c.groupLabel, () => <EnrollableCircle>[]).add(c);
  }
  return groups;
}
