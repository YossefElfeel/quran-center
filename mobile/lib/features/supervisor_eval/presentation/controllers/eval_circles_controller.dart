import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../admin_setup/domain/circle.dart';
import '../../data/supervisor_eval_repository.dart';

part 'eval_circles_controller.g.dart';

/// كل الحلقات المتاحة للمشرف عشان يقيّم.
@riverpod
Future<List<Circle>> evalCircles(Ref ref) =>
    ref.watch(supervisorEvalRepositoryProvider).fetchAllCircles();

/// عدد الطلبة اللي اتقيّموا الشهر ده في كل حلقة (circleId → عدد).
@riverpod
Future<Map<String, int>> evalMonthProgress(Ref ref) {
  final DateTime now = DateTime.now();
  return ref
      .watch(supervisorEvalRepositoryProvider)
      .fetchEvaluatedCountsForMonth(DateTime(now.year, now.month));
}
