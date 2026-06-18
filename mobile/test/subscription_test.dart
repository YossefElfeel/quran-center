import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/subscription/domain/subscription_logic.dart';
import 'package:quran_center/features/subscription/domain/subscription_status.dart';

void main() {
  group('deriveSubscriptionStatus', () {
    test('مفيش دفعات → غير مفعّل', () {
      expect(
        deriveSubscriptionStatus(
          lastPaidMonth: null,
          today: DateTime(2026, 6, 18),
        ),
        SubscriptionStatus.inactive,
      );
    });

    test('مدفوع الشهر الحالي → نشط', () {
      expect(
        deriveSubscriptionStatus(
          lastPaidMonth: DateTime(2026, 6, 1),
          today: DateTime(2026, 6, 18),
        ),
        SubscriptionStatus.active,
      );
    });

    test('مدفوع شهر جاي → نشط', () {
      expect(
        deriveSubscriptionStatus(
          lastPaidMonth: DateTime(2026, 7, 1),
          today: DateTime(2026, 6, 18),
        ),
        SubscriptionStatus.active,
      );
    });

    test('متأخّر شهر + في فترة السماح (يوم ٥) → سماح', () {
      expect(
        deriveSubscriptionStatus(
          lastPaidMonth: DateTime(2026, 5, 1),
          today: DateTime(2026, 6, 5),
        ),
        SubscriptionStatus.grace,
      );
    });

    test('حدّ فترة السماح بالظبط (يوم ٧) → سماح', () {
      expect(
        deriveSubscriptionStatus(
          lastPaidMonth: DateTime(2026, 5, 1),
          today: DateTime(2026, 6, 7),
        ),
        SubscriptionStatus.grace,
      );
    });

    test('متأخّر شهر + بعد فترة السماح (يوم ١٨) → متأخّر', () {
      expect(
        deriveSubscriptionStatus(
          lastPaidMonth: DateTime(2026, 5, 1),
          today: DateTime(2026, 6, 18),
        ),
        SubscriptionStatus.overdue,
      );
    });

    test('متأخّر شهرين حتى في فترة السماح → متأخّر', () {
      expect(
        deriveSubscriptionStatus(
          lastPaidMonth: DateTime(2026, 4, 1),
          today: DateTime(2026, 6, 5),
        ),
        SubscriptionStatus.overdue,
      );
    });
  });

  group('grantsAccess', () {
    test('نشط وسماح يسمحوا بالوصول', () {
      expect(SubscriptionStatus.active.grantsAccess, isTrue);
      expect(SubscriptionStatus.grace.grantsAccess, isTrue);
    });

    test('متأخّر وغير مفعّل يمنعوا الوصول', () {
      expect(SubscriptionStatus.overdue.grantsAccess, isFalse);
      expect(SubscriptionStatus.inactive.grantsAccess, isFalse);
    });
  });
}
