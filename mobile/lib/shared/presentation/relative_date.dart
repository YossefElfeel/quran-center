import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../core/utils/arabic_date.dart';
import '../../core/utils/arabic_numerals.dart';

/// تاريخ نسبي بالعامية للعرض في القوايم: "النهارده"، "امبارح"، "من يومين"،
/// "من ٣ أيام"… ولو أقدم من أسبوع بيرجع اليوم والشهر (مثلاً "٣ أكتوبر").
String relativeDayLabel(AppL10n l, DateTime date, {DateTime? now}) {
  final DateTime local = date.toLocal();
  final DateTime current = (now ?? DateTime.now()).toLocal();
  // أيام تقويمية (UTC عشان التوقيت الصيفي ما يلخبطش الفرق).
  final int days = DateTime.utc(
    current.year,
    current.month,
    current.day,
  ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
  if (days <= 0) return l.fxRelToday;
  if (days == 1) return l.fxRelYesterday;
  if (days == 2) return l.fxRelTwoDaysAgo;
  if (days < 7) return l.fxRelDaysAgo(arabicNumber(days));
  return arabicDayMonthLabel(local, now: current);
}
