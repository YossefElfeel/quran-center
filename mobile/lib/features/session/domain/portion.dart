/// مقطع قرآني (نطاق سور/آيات) — وحدة الحفظ اللي المحرّك بيشتغل عليها.
class Portion {
  const Portion({
    required this.id,
    required this.name,
    required this.surahStart,
    required this.ayahStart,
    required this.surahEnd,
    required this.ayahEnd,
  });

  factory Portion.fromMap(Map<String, dynamic> map) => Portion(
    id: map['id'] as String,
    name: map['name'] as String,
    surahStart: (map['surah_start'] as num).toInt(),
    ayahStart: (map['ayah_start'] as num).toInt(),
    surahEnd: (map['surah_end'] as num).toInt(),
    ayahEnd: (map['ayah_end'] as num).toInt(),
  );

  final String id;
  final String name;
  final int surahStart;
  final int ayahStart;
  final int surahEnd;
  final int ayahEnd;
}
