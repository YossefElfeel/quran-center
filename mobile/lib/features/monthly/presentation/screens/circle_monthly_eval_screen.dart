import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_async_form_sheet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/dispose_with.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../recognition/data/recognition_repository.dart';
import '../../domain/monthly_eval.dart';
import '../controllers/monthly_eval_controllers.dart';

/// المعلّم: التقييم الشهري لطلبة الحلقة (ملخّص + سلوك) — يتسجّل للمشرف يعتمده.
class CircleMonthlyEvalScreen extends ConsumerWidget {
  const CircleMonthlyEvalScreen({
    required this.circleId,
    required this.circleName,
    this.month,
    super.key,
  });

  final String circleId;
  final String circleName;
  final String? month;

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
    await showAppModalSheet<void>(
      context: context,
      title: l.monEvalStudentTitle(s.studentName),
      builder: (BuildContext context) => DisposeWith(
        notifiers: <ChangeNotifier>[summary, behavior],
        child: AppAsyncFormSheet(
          submitLabel: l.monSubmitForApproval,
          successMessage: 'التقييم اتبعت للاعتماد',
          onSubmit: () => ref
              .read(circleMonthlyEvalsProvider(circleId, month: month).notifier)
              .save(
                studentPersonId: s.studentPersonId,
                summary: summary.text.trim(),
                behavior: behavior.text.trim(),
              ),
          fields: <Widget>[
            AppTextField(
              controller: summary,
              minLines: 2,
              maxLines: 4,
              label: l.monPerformanceSummaryLabel,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اكتب ملخّص التقييم'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: behavior,
              minLines: 1,
              maxLines: 3,
              label: l.monBehaviorLabel,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTop(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final List<MonthlyEvalStudent> students =
        ref
            .read(circleMonthlyEvalsProvider(circleId, month: month))
            .asData
            ?.value ??
        <MonthlyEvalStudent>[];
    if (students.isEmpty) return;
    await showAppModalSheet<void>(
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
                style: AppTextStyles.titleMd,
              ),
            ),
            for (final MonthlyEvalStudent s in students)
              ListTile(
                leading: Icon(
                  Icons.emoji_events,
                  color: context.palette.accent,
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
                    AppSnackbar.success(
                      context,
                      l.monTopStudentSnack(s.studentName),
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
      circleMonthlyEvalsProvider(circleId, month: month),
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
          onRetry: () => ref.invalidate(
            circleMonthlyEvalsProvider(circleId, month: month),
          ),
        ),
        data: (List<MonthlyEvalStudent> items) => items.isEmpty
            ? EmptyState(
                message: l.monNoStudentsInCircle,
                icon: Icons.groups_outlined,
                action: TextButton(
                  onPressed: () => ref.invalidate(
                    circleMonthlyEvalsProvider(circleId, month: month),
                  ),
                  child: const Text('تحديث البيانات'),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final MonthlyEvalStudent s = items[i];
                  final (String label, Color color) = s.isApproved
                      ? (l.monStatusApproved, context.palette.success)
                      : s.status == 'returned'
                      ? ('مطلوب تعديل', context.palette.warningText)
                      : s.isSubmitted
                      ? (l.monStatusSubmitted, context.palette.accent)
                      : (l.monStatusPending, context.palette.textSecondary);
                  return Padding(
                    key: ValueKey<String>(s.studentPersonId),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(s.studentName),
                        subtitle: Text(
                          [
                            label,
                            if (s.returnReason != null)
                              'سبب الإرجاع: ${s.returnReason}',
                            if (s.summary != null) s.summary!,
                          ].join('\n'),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: s.isApproved
                              ? null
                              : () => _edit(context, ref, s),
                          child: Text(
                            s.isSubmitted ? l.monEdit : l.monEvaluate,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
