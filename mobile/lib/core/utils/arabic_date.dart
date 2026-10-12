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

/// تاريخ ووقت مختصران للعرض في البطاقات والتفاصيل.
String arabicDateTimeLabel(DateTime date) {
  final DateTime local = date.toLocal();
  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return toArabicDigits('$day/$month/${local.year} - $hour:$minute');
}
