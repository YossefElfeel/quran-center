import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../domain/eval_student.dart';

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
    final AppPalette p = context.palette;
    return AppListCard(
      leading: AppAvatar(name: student.fullName, radius: 22),
      title: student.fullName,
      subtitle: student.selected ? l.supSelectedForEval : null,
      trailing: student.scored
          ? Icon(Icons.check_circle, color: p.success)
          : AppButton(
              label: l.supEvaluate,
              onPressed: onEvaluate,
              variant: AppButtonVariant.text,
              expanded: false,
            ),
    );
  }
}
