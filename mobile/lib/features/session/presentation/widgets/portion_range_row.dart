import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
import '../../data/surah_option.dart';

/// صف اختيار طرف نطاق (سورة + آية) — مشترك بين تحديد المقطع وخطة المراجعة.
class PortionRangeRow extends StatelessWidget {
  const PortionRangeRow({
    required this.title,
    required this.surahs,
    required this.surah,
    required this.onSurah,
    required this.ayahController,
    super.key,
  });

  final String title;
  final List<SurahOption> surahs;
  final int? surah;
  final ValueChanged<int?> onSurah;
  final TextEditingController ayahController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 28,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: DropdownButton<int>(
            isExpanded: true,
            value: surah,
            hint: const Text('السورة'),
            items: surahs
                .map(
                  (SurahOption s) => DropdownMenuItem<int>(
                    value: s.number,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onSurah,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: TextField(
            controller: ayahController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الآية'),
          ),
        ),
      ],
    );
  }
}

/// تحقّق نطاق المقطع: الخانات كاملة + الآيات في حدود السورة + الترتيب صح.
/// بيرجّع رسالة خطأ بالعربي أو null لو سليم.
String? portionRangeError({
  required List<SurahOption> surahs,
  required String name,
  required int? surahStart,
  required int? ayahStart,
  required int? surahEnd,
  required int? ayahEnd,
}) {
  if (name.isEmpty ||
      surahStart == null ||
      ayahStart == null ||
      surahEnd == null ||
      ayahEnd == null ||
      ayahStart <= 0 ||
      ayahEnd <= 0) {
    return 'املا كل الخانات صح';
  }
  final SurahOption? start = _surahByNumber(surahs, surahStart);
  final SurahOption? end = _surahByNumber(surahs, surahEnd);
  if (start != null && ayahStart > start.ayahCount) {
    return 'رقم آية البداية أكبر من آيات السورة';
  }
  if (end != null && ayahEnd > end.ayahCount) {
    return 'رقم آية النهاية أكبر من آيات السورة';
  }
  if (surahEnd < surahStart ||
      (surahEnd == surahStart && ayahEnd < ayahStart)) {
    return 'نهاية المقطع لازم تكون بعد بدايتها';
  }
  return null;
}

SurahOption? _surahByNumber(List<SurahOption> surahs, int number) {
  for (final SurahOption s in surahs) {
    if (s.number == number) return s;
  }
  return null;
}
