import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../recognition/data/recognition_repository.dart';
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
    final AppL10n l = AppL10n.of(context);
    final TextEditingController summary = TextEditingController(
      text: s.summary ?? '',
    );
    final TextEditingController behavior = TextEditingController(
      text: s.behavior ?? '',
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.monEvalStudentTitle(s.studentName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: summary,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l.monPerformanceSummaryLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: behavior,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.monBehaviorLabel),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.monSubmitForApproval),
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

  Future<void> _pickTop(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final List<MonthlyEvalStudent> students =
        ref.read(circleMonthlyEvalsProvider(circleId)).asData?.value ??
        <MonthlyEvalStudent>[];
    if (students.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l.monPickTopTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final MonthlyEvalStudent s in students)
              ListTile(
                leading: const Icon(
                  Icons.emoji_events,
                  color: AppColors.accent,
                ),
                title: Text(s.studentName),
                onTap: () async {
                  await ref
                      .read(recognitionRepositoryProvider)
                      .pickTopStudent(
                        circleId: circleId,
                        studentPersonId: s.studentPersonId,
                      );
                  ref.invalidate(honorBoardProvider);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.monTopStudentSnack(s.studentName)),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<MonthlyEvalStudent>> state = ref.watch(
      circleMonthlyEvalsProvider(circleId),
    );
    return AppScaffold(
      title: l.monEvalScreenTitle(circleName),
      actions: <Widget>[
        IconButton(
          tooltip: l.monTopStudentTooltip,
          icon: const Icon(Icons.emoji_events),
          onPressed: () => _pickTop(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.monLoadStudentsFailed,
          onRetry: () => ref.invalidate(circleMonthlyEvalsProvider(circleId)),
        ),
        data: (List<MonthlyEvalStudent> items) => items.isEmpty
            ? EmptyState(
                message: l.monNoStudentsInCircle,
                icon: Icons.groups_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final MonthlyEvalStudent s = items[i];
                  final (String label, Color color) = s.isApproved
                      ? (l.monStatusApproved, AppColors.success)
                      : s.isSubmitted
                      ? (l.monStatusSubmitted, AppColors.accent)
                      : (l.monStatusPending, AppColors.textSecondary);
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
                        child: Text(s.isSubmitted ? l.monEdit : l.monEvaluate),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
