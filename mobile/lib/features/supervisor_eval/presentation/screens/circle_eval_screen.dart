import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/eval_student.dart';
import '../controllers/circle_eval_controller.dart';
import '../widgets/criteria_eval_sheet.dart';
import '../widgets/eval_student_tile.dart';

/// تقييم حلقة: اختيار عشوائي + تقييم ٣×١٠ لكل طالب.
class CircleEvalScreen extends ConsumerWidget {
  const CircleEvalScreen({
    required this.circleId,
    required this.circleName,
    super.key,
  });

  final String circleId;
  final String circleName;

  void _openEval(BuildContext context, EvalStudent s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => CriteriaEvalSheet(
        circleId: circleId,
        studentPersonId: s.studentPersonId,
        studentName: s.fullName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<EvalStudent>> state = ref.watch(
      circleEvalControllerProvider(circleId),
    );
    return AppScaffold(
      title: circleName,
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.supStudentsLoadError,
          onRetry: () => ref.invalidate(circleEvalControllerProvider(circleId)),
        ),
        data: (List<EvalStudent> students) {
          if (students.isEmpty) {
            return EmptyState(
              message: l.supNoStudentsInCircle,
              icon: Icons.groups_outlined,
            );
          }
          final CircleEvalController notifier = ref.read(
            circleEvalControllerProvider(circleId).notifier,
          );
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: l.supRandomPick,
                  icon: Icons.shuffle,
                  onPressed: () => notifier.randomPick(3),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  itemCount: students.length,
                  itemBuilder: (BuildContext context, int i) => EvalStudentTile(
                    key: ValueKey<String>(students[i].studentPersonId),
                    student: students[i],
                    onEvaluate: () => _openEval(context, students[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
