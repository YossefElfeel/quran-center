import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/monthly_eval_repository.dart';
import '../../domain/monthly_eval.dart';

part 'monthly_eval_controllers.g.dart';

/// تقييمات الشهر لطلبة حلقة + حفظ (المعلّم).
@riverpod
class CircleMonthlyEvals extends _$CircleMonthlyEvals {
  @override
  Future<List<MonthlyEvalStudent>> build(String circleId, {String? month}) =>
      ref
          .watch(monthlyEvalRepositoryProvider)
          .fetchCircleEvals(circleId, month: month);

  Future<void> save({
    required String studentPersonId,
    String? summary,
    String? behavior,
  }) async {
    await ref
        .read(monthlyEvalRepositoryProvider)
        .saveEval(
          studentPersonId: studentPersonId,
          month: month,
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

  Future<void> returnForRevision(String id, String reason) async {
    await ref.read(monthlyEvalRepositoryProvider).returnForRevision(id, reason);
    ref.invalidateSelf();
    await future;
  }

  Future<void> approve(String id) async {
    await ref.read(monthlyEvalRepositoryProvider).approve(id);
    ref.invalidateSelf();
    await future;
  }
}
