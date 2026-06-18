import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../domain/monthly_plan_view.dart';
import '../controllers/child_extras_controller.dart';

/// خطة الشهر للحلقة (ولي الأمر بيشوف هيدرس إيه الشهر ده).
class ChildMonthlyPlanSection extends ConsumerWidget {
  const ChildMonthlyPlanSection({required this.studentPersonId, super.key});

  final String studentPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MonthlyPlanView?> state = ref.watch(
      childMonthlyPlanProvider(studentPersonId),
    );
    return state.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (MonthlyPlanView? plan) {
        if (plan == null || plan.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'خطة الشهر',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (plan.curriculumPlan != null &&
                    plan.curriculumPlan!.trim().isNotEmpty)
                  _Line(icon: Icons.menu_book, text: plan.curriculumPlan!),
                if (plan.teachingMethod != null &&
                    plan.teachingMethod!.trim().isNotEmpty)
                  _Line(icon: Icons.school, text: plan.teachingMethod!),
                if (plan.portionsRef != null &&
                    plan.portionsRef!.trim().isNotEmpty)
                  _Line(icon: Icons.bookmark, text: plan.portionsRef!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
