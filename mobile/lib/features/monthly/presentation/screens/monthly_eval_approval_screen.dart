import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_approval_actions.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_paged_list.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/monthly_eval_repository.dart';
import '../../domain/monthly_eval.dart';
import '../controllers/monthly_eval_controllers.dart';

/// المشرف: اعتماد التقييم الشهري المُرسَل من المعلّمين.
class MonthlyEvalApprovalScreen extends ConsumerWidget {
  const MonthlyEvalApprovalScreen({super.key});

  String _monthLabel(PendingMonthlyEval e) =>
      '${arabicNumber(e.month.month)}/${arabicNumber(e.month.year)}';

  /// معاينة كاملة قبل الاعتماد: الملخّص + الملاحظة السلوكية + اعتماد من جوّه.
  void _openPreview(BuildContext context, WidgetRef ref, PendingMonthlyEval e) {
    showAppModalSheet<void>(
      context: context,
      title: e.studentName,
      builder: (BuildContext context) {
        final AppL10n l = AppL10n.of(context);
        final AppPalette p = context.palette;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.event, size: 16, color: p.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _monthLabel(e),
                  style: AppTextStyles.labelLg.copyWith(color: p.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PreviewField(
              label: l.monPerformanceSummaryLabel,
              value: e.summary,
            ),
            const SizedBox(height: AppSpacing.md),
            _PreviewField(label: l.monBehaviorLabel, value: e.behavior),
            const SizedBox(height: AppSpacing.lg),
            AppApprovalActions(
              onApprove: () =>
                  ref.read(pendingMonthlyEvalsProvider.notifier).approve(e.id),
              onReturn: (String reason) => ref
                  .read(pendingMonthlyEvalsProvider.notifier)
                  .returnForRevision(e.id, reason),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<PendingMonthlyEval>> state = ref.watch(
      pendingMonthlyEvalsProvider,
    );
    return AppScaffold(
      title: l.navMonthlyEvalApproval,
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.monLoadQueueFailed,
          onRetry: () => ref.invalidate(pendingMonthlyEvalsProvider),
        ),
        data: (List<PendingMonthlyEval> items) => items.isEmpty
            ? EmptyState(
                message: l.monNoPendingEvals,
                icon: Icons.done_all,
                title: 'كل التقييمات متراجعة',
                action: TextButton(
                  onPressed: () => ref.invalidate(pendingMonthlyEvalsProvider),
                  child: const Text('تحديث التقييمات'),
                ),
              )
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(pendingMonthlyEvalsProvider),
                child: AppPagedList<PendingMonthlyEval>(
                  items: items,
                  loadPage: (offset) => ref
                      .read(monthlyEvalRepositoryProvider)
                      .fetchPending(offset: offset),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemBuilder:
                      (BuildContext context, PendingMonthlyEval e, int i) {
                        return AppListCard(
                          leadingIcon: Icons.grading,
                          title: e.studentName,
                          subtitle: '${e.summary ?? '—'}\n${_monthLabel(e)}',
                          onTap: () => _openPreview(context, ref, e),
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                ),
              ),
      ),
    );
  }
}

/// حقل معاينة: عنوان + قيمة (أو شرطة لو فاضي).
class _PreviewField extends StatelessWidget {
  const _PreviewField({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String? value = this.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value == null || value.isEmpty ? '—' : value,
          style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
        ),
      ],
    );
  }
}
