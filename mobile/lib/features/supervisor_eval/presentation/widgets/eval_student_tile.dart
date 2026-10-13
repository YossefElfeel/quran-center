import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_date.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../domain/eval_criterion.dart';
import '../../domain/eval_student.dart';
import '../supervisor_eval_labels.dart';

/// بلاطة طالب في تقييم المشرف — تمييز المختار + شارة "اتقيّم" + زر تقييم.
class EvalStudentTile extends StatelessWidget {
  const EvalStudentTile({
    required this.student,
    required this.onEvaluate,
    super.key,
  });

  final EvalStudent student;
  final VoidCallback onEvaluate;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final String average = toArabicDigits(
      student.average
          .toStringAsFixed(1)
          .replaceAll('.', '٫'), // l10n-ignore: Arabic decimal separator
    );
    String score(EvalCriterion criterion) =>
        arabicNumber(student.scores[criterion] ?? 0);
    final String breakdown = l.fyEvalBreakdown(
      score(EvalCriterion.memorization),
      score(EvalCriterion.recitation),
      score(EvalCriterion.mushafReading),
    );
    // آخر تقييم من شهر فات؟ مايتحسبش "اتقيّم" على الشهر ده — نعرضه كمرجع بس.
    final DateTime? at = student.evaluatedAt?.toLocal();
    final DateTime now = DateTime.now();
    final bool fromOlderMonth =
        student.scored &&
        at != null &&
        (at.year != now.year || at.month != now.month);
    final bool doneThisMonth = student.scored && !fromOlderMonth;
    final String? subtitle = fromOlderMonth
        ? <String>[
            if (student.selected) l.supSelectedForEval,
            l.fyEvalNotThisMonth,
            l.fyEvalPrevious(
              arabicMonthLabel(at),
              average,
              student.level.label(l),
            ),
          ].join('\n')
        : doneThisMonth
        ? <String>[
            l.supEvaluationResult(average, student.level.label(l)),
            breakdown,
          ].join('\n')
        : student.selected
        ? l.supSelectedForEval
        : null;
    return AppListCard(
      leading: AppAvatar(name: student.fullName, radius: 22),
      title: student.fullName,
      subtitle: subtitle,
      onTap: student.scored ? onEvaluate : null,
      trailing: AppButton(
        label: doneThisMonth ? l.supViewEvaluation : l.supEvaluate,
        icon: doneThisMonth ? Icons.check_circle : null,
        onPressed: onEvaluate,
        variant: AppButtonVariant.text,
        expanded: false,
      ),
    );
  }
}
