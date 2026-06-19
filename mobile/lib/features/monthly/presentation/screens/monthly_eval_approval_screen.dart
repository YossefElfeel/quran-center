import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/monthly_eval.dart';
import '../controllers/monthly_eval_controllers.dart';

/// المشرف: اعتماد التقييم الشهري المُرسَل من المعلّمين.
class MonthlyEvalApprovalScreen extends ConsumerWidget {
  const MonthlyEvalApprovalScreen({super.key});

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
            ? EmptyState(message: l.monNoPendingEvals, icon: Icons.done_all)
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(pendingMonthlyEvalsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final PendingMonthlyEval e = items[i];
                    return AppListCard(
                      leadingIcon: Icons.grading,
                      title: e.studentName,
                      subtitle:
                          '${e.summary ?? '—'}\n'
                          '${arabicNumber(e.month.month)}/'
                          '${arabicNumber(e.month.year)}',
                      trailing: AppButton(
                        label: l.monApprove,
                        onPressed: () => ref
                            .read(pendingMonthlyEvalsProvider.notifier)
                            .approve(e.id),
                        variant: AppButtonVariant.tonal,
                        expanded: false,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
