import 'subscription_status.dart';

/// ملخّص أسرة في شاشة الأدمن (مع حالة الاشتراك المشتقّة من آخر دفعة).
class HouseholdSummary {
  const HouseholdSummary({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.status,
  });

  final String id;
  final String name;
  final double monthlyAmount;
  final SubscriptionStatus status;
}
