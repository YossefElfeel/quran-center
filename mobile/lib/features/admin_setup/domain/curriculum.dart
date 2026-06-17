/// نوع المنهج — قرآن أو تأسيس عربي.
enum CurriculumType {
  quran,
  arabicFoundation;

  /// القيمة المخزّنة في القاعدة (enum القاعدة: quran|arabic_foundation).
  String get dbValue => switch (this) {
        CurriculumType.quran => 'quran',
        CurriculumType.arabicFoundation => 'arabic_foundation',
      };

  String get labelAr => switch (this) {
        CurriculumType.quran => 'قرآن',
        CurriculumType.arabicFoundation => 'تأسيس عربي',
      };

  static CurriculumType fromDb(String value) => switch (value) {
        'arabic_foundation' => CurriculumType.arabicFoundation,
        _ => CurriculumType.quran,
      };
}

/// منهج (entity) — بيانات نقية بدون أي اعتماد على Supabase.
class Curriculum {
  const Curriculum({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final CurriculumType type;

  factory Curriculum.fromMap(Map<String, dynamic> map) => Curriculum(
        id: map['id'] as String,
        name: map['name'] as String,
        type: CurriculumType.fromDb(map['type'] as String),
      );
}
