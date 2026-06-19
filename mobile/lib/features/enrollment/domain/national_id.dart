// أدوات الرقم القومي المصري (تطبيع + استخراج) — منطق نقي قابل للاختبار.
// التخزين الآمن (HMAC blind index + تشفير) بيتعمل سيرفر-سايد عبر
// RPC `set_person_national_id`؛ هنا قراءة/تنظيف بس.

const Map<int, String> _arabicIndicToWestern = <int, String>{
  0x0660: '0',
  0x0661: '1',
  0x0662: '2',
  0x0663: '3',
  0x0664: '4',
  0x0665: '5',
  0x0666: '6',
  0x0667: '7',
  0x0668: '8',
  0x0669: '9',
  0x06F0: '0',
  0x06F1: '1',
  0x06F2: '2',
  0x06F3: '3',
  0x06F4: '4',
  0x06F5: '5',
  0x06F6: '6',
  0x06F7: '7',
  0x06F8: '8',
  0x06F9: '9',
};

/// بيحوّل الأرقام العربية-الهندية/الفارسية لغربية، ويشيل أي حرف مش رقم.
String normalizeDigits(String input) {
  final StringBuffer out = StringBuffer();
  for (final int rune in input.runes) {
    final String? mapped = _arabicIndicToWestern[rune];
    if (mapped != null) {
      out.write(mapped);
    } else if (rune >= 0x30 && rune <= 0x39) {
      out.write(String.fromCharCode(rune));
    }
  }
  return out.toString();
}

/// بيدوّر على مجموعة ١٤ رقم متتالية في نص (للرقم القومي المصري). بيفضّل توكن
/// طوله ١٤ بالظبط؛ بيرجّع null لو مفيش.
String? extractNationalId(String text) {
  final RegExp digitRun = RegExp(r'[0-9٠-٩۰-۹]+');
  final List<String> normRuns = digitRun
      .allMatches(text)
      .map((Match m) => normalizeDigits(m.group(0)!))
      .toList();
  for (final String run in normRuns) {
    if (run.length == 14) return run;
  }
  for (final String run in normRuns) {
    final Match? sub = RegExp(r'\d{14}').firstMatch(run);
    if (sub != null) return sub.group(0);
  }
  return null;
}

/// تحقّق: ١٤ رقم بالظبط (بعد التطبيع).
bool isValidNationalId(String value) =>
    RegExp(r'^\d{14}$').hasMatch(normalizeDigits(value));
