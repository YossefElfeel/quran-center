import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../parent_portal/domain/child_history.dart';
import '../../data/supervisor_eval_repository.dart';
import '../../domain/circle_roster_score.dart';

part 'attention_detail_controllers.g.dart';

/// سجلّ تسميع طالب متعثّر (للمشرف يشوف نمط التعثّر).
@riverpod
Future<List<TasmeeHistoryEntry>> studentTasmeeHistory(
  Ref ref,
  String studentPersonId,
) => ref
    .watch(supervisorEvalRepositoryProvider)
    .fetchStudentTasmeeHistory(studentPersonId);

/// تفصيل درجات حلقة على مقطعها الحالي.
@riverpod
Future<CircleScores> circleRosterScores(Ref ref, String circleId) => ref
    .watch(supervisorEvalRepositoryProvider)
    .fetchCircleRosterScores(circleId);
