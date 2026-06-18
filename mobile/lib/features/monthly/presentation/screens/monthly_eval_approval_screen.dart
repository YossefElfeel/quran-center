import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/monthly_eval.dart';
import '../controllers/monthly_eval_controllers.dart';

/// المشرف: اعتماد التقييم الشهري المُرسَل من المعلّمين.
class MonthlyEvalApprovalScreen extends ConsumerWidget {
  const MonthlyEvalApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PendingMonthlyEval>> state = ref.watch(
      pendingMonthlyEvalsProvider,
    );
    return AppScaffold(
      title: 'اعتماد التقييم الشهري',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الطابور',
          onRetry: () => ref.invalidate(pendingMonthlyEvalsProvider),
        ),
        data: (List<PendingMonthlyEval> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش تقييمات مستنية اعتماد',
                icon: Icons.done_all,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final PendingMonthlyEval e = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      title: Text(e.studentName),
                      subtitle: Text(
                        '${e.summary ?? '—'}\n'
                        '${arabicNumber(e.month.month)}/'
                        '${arabicNumber(e.month.year)}',
                      ),
                      isThreeLine: true,
                      trailing: FilledButton(
                        onPressed: () => ref
                            .read(pendingMonthlyEvalsProvider.notifier)
                            .approve(e.id),
                        child: const Text('اعتمد'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
