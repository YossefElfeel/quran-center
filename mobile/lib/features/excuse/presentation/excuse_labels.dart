import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../core/utils/arabic_date.dart';
import '../../../core/utils/arabic_numerals.dart';
import '../domain/pending_excuse.dart';

/// يوم الغياب للعرض: "١٢ أكتوبر ٢٠٢٦".
String excuseDateLabel(DateTime date) =>
    '${arabicNumber(date.day)} ${arabicMonthLabel(date)}';

/// وقت نسبي بالعامية: "دلوقتي"، "من ٣ ساعات"، "امبارح"… وأقدم من أسبوع →
/// التاريخ نفسه.
String excuseRelativeTime(AppL10n l, DateTime at, {DateTime? now}) {
  final DateTime current = (now ?? DateTime.now()).toUtc();
  final Duration diff = current.difference(at.toUtc());
  if (diff.inMinutes < 1) return l.fyTimeJustNow;
  if (diff.inHours < 1) {
    return l.fyTimeMinutesAgo(diff.inMinutes, arabicNumber(diff.inMinutes));
  }
  if (diff.inDays < 1) {
    return l.fyTimeHoursAgo(diff.inHours, arabicNumber(diff.inHours));
  }
  if (diff.inDays < 7) {
    return l.fyTimeDaysAgo(diff.inDays, arabicNumber(diff.inDays));
  }
  return excuseDateLabel(at.toLocal());
}

/// سطر "طلبها: <المعلّم> · <من إمتى>" (أو "اتطلب <من إمتى>" لو مش معروف).
String excuseRequestedLine(AppL10n l, PendingExcuse excuse, {DateTime? now}) {
  final String time = excuseRelativeTime(l, excuse.createdAt, now: now);
  final String? name = excuse.requesterName;
  return name == null || name.trim().isEmpty
      ? l.fyExcuseRequestedAt(time)
      : l.fyExcuseRequestedBy(name, time);
}
