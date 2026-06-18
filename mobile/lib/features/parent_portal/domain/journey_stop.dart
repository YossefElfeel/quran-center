/// محطة في رحلة الطالب (حلقة/معلّم + المدى المحفوظ) — أساس "حق المحفّظ".
class JourneyStop {
  const JourneyStop({
    required this.circleName,
    required this.teacherName,
    this.fromPoint,
    this.toPoint,
    this.ajza = 0,
    this.pages = 0,
    this.ongoing = false,
  });

  factory JourneyStop.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? circle = map['circle'] as Map<String, dynamic>?;
    final Map<String, dynamic>? teacher =
        map['teacher'] as Map<String, dynamic>?;
    return JourneyStop(
      circleName: (circle?['name'] as String?) ?? 'حلقة',
      teacherName: (teacher?['full_name'] as String?) ?? 'المعلّم',
      fromPoint: map['from_point'] as String?,
      toPoint: map['to_point'] as String?,
      ajza: (map['ajza'] as num?)?.toDouble() ?? 0,
      pages: (map['pages'] as num?)?.toInt() ?? 0,
      ongoing: map['ended_at'] == null,
    );
  }

  final String circleName;
  final String teacherName;
  final String? fromPoint;
  final String? toPoint;
  final double ajza;
  final int pages;
  final bool ongoing;
}
