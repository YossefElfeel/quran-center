import 'arabic_numerals.dart';

/// أسماء الشهور الميلادية بالعربي (للعرض فقط).
const List<String> _arGregorianMonths = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// تسمية الشهر بالعربي مع السنة بأرقام عربية (مثلاً "يونيو ٢٠٢٦").
String arabicMonthLabel(DateTime date) =>
    '${_arGregorianMonths[date.month - 1]} ${toArabicDigits(date.year.toString())}';
