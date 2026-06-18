import 'package:flutter/material.dart';

import '../../../../shared/theme/tokens.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.md,
      ),
      color: student.selected ? AppColors.accent.withValues(alpha: 0.12) : null,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Icon(Icons.person),
        ),
        title: Text(student.fullName),
        subtitle: student.selected
            ? const Text(
                'مختار للتقييم',
                style: TextStyle(color: AppColors.accent),
              )
            : null,
        trailing: student.scored
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : TextButton(onPressed: onEvaluate, child: const Text('قيّم')),
      ),
    );
  }
}
