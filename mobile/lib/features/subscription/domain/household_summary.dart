import 'subscription_logic.dart';
import 'subscription_status.dart';

/// ملخّص أسرة في شاشة الأدمن (مع حالة الاشتراك المشتقّة من آخر دفعة).
class HouseholdSummary {
  const HouseholdSummary({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.status,
    this.lastPaidMonth,
  });

  final String id;
  final String name;
  final double monthlyAmount;
  final SubscriptionStatus status;

  /// أول يوم في آخر شهر مدفوع (null = مفيش دفعات).
  final DateTime? lastPaidMonth;

  /// عدد الشهور المتأخّرة لحد [today] (null = مفيش دفعات خالص).
  int? monthsLate(DateTime today) =>
      monthsBehind(lastPaidMonth: lastPaidMonth, today: today);

  /// إجمالي المطلوب لحد [today] (شهور التأخير × الاشتراك الشهري).
  num amountDue(DateTime today) =>
      totalDue(months: monthsLate(today) ?? 0, monthlyAmount: monthlyAmount);
}
