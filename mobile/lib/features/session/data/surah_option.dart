/// عنصر سورة لاختيار نطاق المقطع (رقم + اسم + عدد آيات للتحقق).
class SurahOption {
  const SurahOption({
    required this.number,
    required this.name,
    required this.ayahCount,
  });

  factory SurahOption.fromMap(Map<String, dynamic> map) => SurahOption(
    number: (map['number'] as num).toInt(),
    // العمود في الداتابيز اسمه name_ar (مش name) — ده كان سبب فشل تحميل السور.
    name: (map['name_ar'] ?? map['name']) as String,
    ayahCount: (map['ayah_count'] as num).toInt(),
  );

  final int number;
  final String name;
  final int ayahCount;
}
