/// تحويل الأرقام الغربية (0-9) لأرقام عربية-هندية (٠-٩) **للعرض فقط**.
/// التخزين/الإرسال بيفضل بأرقام غربية.
String toArabicDigits(String input) {
  const List<String> western = <String>[
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];
  const List<String> eastern = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];
  String out = input;
  for (int i = 0; i < western.length; i++) {
    out = out.replaceAll(western[i], eastern[i]);
  }
  return out;
}

/// رقم جاهز للعرض بالأرقام العربية.
String arabicNumber(num value) => toArabicDigits(value.toString());
