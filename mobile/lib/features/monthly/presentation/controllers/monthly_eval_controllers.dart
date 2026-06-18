import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/monthly_eval_repository.dart';
import '../../domain/monthly_eval.dart';

part 'monthly_eval_controllers.g.dart';

/// تقييمات الشهر لطلبة حلقة + حفظ (المعلّم).
@riverpod
class CircleMonthlyEvals extends _$CircleMonthlyEvals {
  @override
  Future<List<MonthlyEvalStudent>> build(String circleId) =>
      ref.watch(monthlyEvalRepositoryProvider).fetchCircleEvals(circleId);

  Future<void> save({
    required String studentPersonId,
    String? summary,
    String? behavior,
  }) async {
    await ref
        .read(monthlyEvalRepositoryProvider)
        .saveEval(
          studentPersonId: studentPersonId,
          summary: summary,
          behavior: behavior,
        );
    ref.invalidateSelf();
    await future;
  }
}

/// طابور اعتماد التقييم الشهري + اعتماد (المشرف).
@riverpod
class PendingMonthlyEvals extends _$PendingMonthlyEvals {
  @override
  Future<List<PendingMonthlyEval>> build() =>
      ref.watch(monthlyEvalRepositoryProvider).fetchPending();

  Future<void> approve(String id) async {
    await ref.read(monthlyEvalRepositoryProvider).approve(id);
    ref.invalidateSelf();
    await future;
  }
}
