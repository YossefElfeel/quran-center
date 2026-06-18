import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../data/subscription_repository.dart';
import '../../domain/household_summary.dart';

part 'households_controller.g.dart';

/// أسر الاشتراكات (مع الحالة) + إنشاء أسرة + تسجيل دفعة.
@riverpod
class HouseholdsController extends _$HouseholdsController {
  @override
  Future<List<HouseholdSummary>> build() =>
      ref.watch(subscriptionRepositoryProvider).fetchHouseholds();

  Future<void> createHousehold(String name) async {
    await ref.read(subscriptionRepositoryProvider).createHousehold(name);
    ref.invalidateSelf();
    await future;
  }

  Future<void> recordPayment(HouseholdSummary household) async {
    final String? adminId = await ref.read(currentPersonIdProvider.future);
    await ref
        .read(subscriptionRepositoryProvider)
        .recordCurrentMonthPayment(
          householdId: household.id,
          amount: household.monthlyAmount,
          recordedBy: adminId,
        );
    ref.invalidateSelf();
    await future;
  }
}
