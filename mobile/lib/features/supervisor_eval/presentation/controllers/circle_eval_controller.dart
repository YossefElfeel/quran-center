import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../data/supervisor_eval_repository.dart';
import '../../domain/eval_criterion.dart';
import '../../domain/eval_selection.dart';
import '../../domain/eval_student.dart';
import '../../domain/supervisor_eval_logic.dart';

part 'circle_eval_controller.g.dart';

/// تقييم حلقة: تحميل الطلبة، اختيار عشوائي، وتسجيل تقييم ٣×١٠ لكل طالب.
@riverpod
class CircleEvalController extends _$CircleEvalController {
  EvalSelection _selection = EvalSelection.manual;

  @override
  Future<List<EvalStudent>> build(String circleId) {
    return ref.watch(supervisorEvalRepositoryProvider).fetchStudents(circleId);
  }

  /// يختار [count] طلبة عشوائيًا (يعلّمهم selected) ويضبط النوع = عشوائي.
  void randomPick(int count) {
    final List<EvalStudent>? students = state.asData?.value;
    if (students == null) return;
    _selection = EvalSelection.random;
    final List<String> picked = pickRandom(
      students.map((EvalStudent s) => s.studentPersonId).toList(),
      count,
      seed: DateTime.now().microsecondsSinceEpoch,
    );
    final Set<String> ids = picked.toSet();
    state = AsyncData<List<EvalStudent>>(
      students
          .map(
            (EvalStudent s) =>
                s.copyWith(selected: ids.contains(s.studentPersonId)),
          )
          .toList(),
    );
  }

  /// يسجّل تقييم طالب (٣ معايير) — ينشئ تقييم ويحفظ درجاته.
  Future<void> recordEval(
    String studentPersonId,
    Map<EvalCriterion, int> scores,
  ) async {
    final List<EvalStudent>? students = state.asData?.value;
    if (students == null) return;
    final String? supervisorId = await ref.read(currentPersonIdProvider.future);
    final SupervisorEvalRepository repo = ref.read(
      supervisorEvalRepositoryProvider,
    );
    final String evalId = await repo.createEvaluation(
      circleId: circleId,
      selection: _selection.dbValue,
      supervisorId: supervisorId,
    );
    await repo.saveScores(
      evaluationId: evalId,
      studentPersonId: studentPersonId,
      scores: scores,
    );
    state = AsyncData<List<EvalStudent>>(
      students
          .map(
            (EvalStudent s) => s.studentPersonId == studentPersonId
                ? s.copyWith(scored: true)
                : s,
          )
          .toList(),
    );
  }
}
