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

/// عدد الشهور اللي الأسرة متأخّرة فيها: من بعد آخر شهر مدفوع لحد الشهر الحالي
/// (شامل). مدفوع للشهر الحالي أو أبعد → ٠. مفيش دفعات → null (مش معروف).
int? monthsBehind({required DateTime? lastPaidMonth, required DateTime today}) {
  if (lastPaidMonth == null) return null;
  final int diff =
      (today.year - lastPaidMonth.year) * 12 +
      (today.month - lastPaidMonth.month);
  return diff < 0 ? 0 : diff;
}

/// الشهور المستحقة (مش مدفوعة) في آخر [window] شهر — الأحدث الأول — من غير ما
/// نرجع لقبل شهر إنشاء الأسرة. [monthlyAmount] ≤ ٠ = أسرة معفية → مفيش مستحق.
List<DateTime> dueMonths({
  required DateTime today,
  required DateTime householdCreatedAt,
  required Iterable<DateTime> paidMonths,
  required num monthlyAmount,
  int window = 12,
}) {
  if (monthlyAmount <= 0) return const <DateTime>[];
  final Set<int> paid = paidMonths
      .map((DateTime m) => m.year * 12 + m.month)
      .toSet();
  final DateTime created = DateTime(
    householdCreatedAt.year,
    householdCreatedAt.month,
  );
  final List<DateTime> due = <DateTime>[];
  for (int i = 0; i < window; i++) {
    final DateTime month = DateTime(today.year, today.month - i);
    if (month.isBefore(created)) break;
    if (!paid.contains(month.year * 12 + month.month)) due.add(month);
  }
  return due;
}

/// إجمالي المطلوب = عدد الشهور المستحقة × الاشتراك الشهري.
num totalDue({required int months, required num monthlyAmount}) =>
    monthlyAmount <= 0 || months <= 0 ? 0 : months * monthlyAmount;
