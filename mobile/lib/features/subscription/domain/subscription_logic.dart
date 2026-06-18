import 'subscription_status.dart';

/// فترة السماح الافتراضية (أيام من أول الشهر) قبل ما الاشتراك يبقى متأخّر.
const int defaultGraceDays = 7;

/// يشتقّ حالة الاشتراك من آخر شهر مدفوع وتاريخ النهارده.
///
/// [lastPaidMonth] = أول يوم في آخر شهر مدفوع (null = مفيش دفعات خالص).
/// - مدفوع للشهر الحالي (أو أبعد) → نشط.
/// - متأخّر شهر واحد وإحنا لسه في فترة السماح → سماح.
/// - غير كده → متأخّر. ومفيش دفعات → غير مفعّل.
SubscriptionStatus deriveSubscriptionStatus({
  required DateTime? lastPaidMonth,
  required DateTime today,
  int graceDays = defaultGraceDays,
}) {
  if (lastPaidMonth == null) return SubscriptionStatus.inactive;
  final DateTime current = DateTime(today.year, today.month);
  final DateTime paid = DateTime(lastPaidMonth.year, lastPaidMonth.month);
  if (!paid.isBefore(current)) return SubscriptionStatus.active;
  final int monthsBehind =
      (current.year - paid.year) * 12 + (current.month - paid.month);
  if (monthsBehind == 1 && today.day <= graceDays) {
    return SubscriptionStatus.grace;
  }
  return SubscriptionStatus.overdue;
}
