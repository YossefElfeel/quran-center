import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/monthly_eval.dart';
import '../controllers/monthly_eval_controllers.dart';

/// المعلّم: التقييم الشهري لطلبة الحلقة (ملخّص + سلوك) — يتسجّل للمشرف يعتمده.
class CircleMonthlyEvalScreen extends ConsumerWidget {
  const CircleMonthlyEvalScreen({
    required this.circleId,
    required this.circleName,
    super.key,
  });

  final String circleId;
  final String circleName;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    MonthlyEvalStudent s,
  ) async {
    final TextEditingController summary = TextEditingController(
      text: s.summary ?? '',
    );
    final TextEditingController behavior = TextEditingController(
      text: s.behavior ?? '',
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('تقييم ${s.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: summary,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'ملخّص الأداء'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: behavior,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'السلوك'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إرسال للاعتماد'),
          ),
        ],
      ),
    );
    final String sm = summary.text;
    final String bh = behavior.text;
    summary.dispose();
    behavior.dispose();
    if (ok == true) {
      await ref
          .read(circleMonthlyEvalsProvider(circleId).notifier)
          .save(studentPersonId: s.studentPersonId, summary: sm, behavior: bh);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MonthlyEvalStudent>> state = ref.watch(
      circleMonthlyEvalsProvider(circleId),
    );
    return AppScaffold(
      title: 'تقييم شهري — $circleName',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الطلبة',
          onRetry: () => ref.invalidate(circleMonthlyEvalsProvider(circleId)),
        ),
        data: (List<MonthlyEvalStudent> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش طلبة في الحلقة',
                icon: Icons.groups_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final MonthlyEvalStudent s = items[i];
                  final (String label, Color color) = s.isApproved
                      ? ('معتمد', AppColors.success)
                      : s.isSubmitted
                      ? ('مُرسل', AppColors.accent)
                      : ('لسه', AppColors.textSecondary);
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      title: Text(s.studentName),
                      subtitle: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: s.isApproved
                            ? null
                            : () => _edit(context, ref, s),
                        child: Text(s.isSubmitted ? 'تعديل' : 'تقييم'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
