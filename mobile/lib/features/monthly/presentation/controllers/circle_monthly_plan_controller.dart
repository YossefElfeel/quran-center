import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/monthly_repository.dart';
import '../../domain/monthly_plan.dart';

part 'circle_monthly_plan_controller.g.dart';

/// خطة الشهر للحلقة (تحميل + حفظ) — للمعلّم.
@riverpod
class CircleMonthlyPlanController extends _$CircleMonthlyPlanController {
  @override
  Future<MonthlyPlan?> build(String circleId) =>
      ref.watch(monthlyRepositoryProvider).fetchThisMonthPlan(circleId);

  Future<void> save({
    String? curriculumPlan,
    String? teachingMethod,
    String? portionsRef,
  }) async {
    await ref
        .read(monthlyRepositoryProvider)
        .savePlan(
          circleId: circleId,
          curriculumPlan: curriculumPlan,
          teachingMethod: teachingMethod,
          portionsRef: portionsRef,
        );
    ref.invalidateSelf();
    await future;
  }
}
