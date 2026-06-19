import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/teacher_dev_entry.dart';
import '../controllers/teacher_controllers.dart';

/// المشرف: اعتماد تطوّر المعلّمين (طابور المُرسَل).
class DevelopmentApprovalScreen extends ConsumerWidget {
  const DevelopmentApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<TeacherDevEntry>> state = ref.watch(
      pendingDevelopmentProvider,
    );
    return AppScaffold(
      title: l.navTeacherDev,
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.tchQueueLoadFailed,
          onRetry: () => ref.invalidate(pendingDevelopmentProvider),
        ),
        data: (List<TeacherDevEntry> items) => items.isEmpty
            ? EmptyState(message: l.tchNoPendingApprovals, icon: Icons.done_all)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final TeacherDevEntry e = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                      ),
                      title: Text(e.teacherName ?? l.tchTeacherFallback),
                      subtitle: Text(
                        '${e.progress ?? '—'}\n'
                        '${arabicNumber(e.month.month)}/'
                        '${arabicNumber(e.month.year)}',
                      ),
                      isThreeLine: true,
                      trailing: FilledButton(
                        onPressed: () => ref
                            .read(pendingDevelopmentProvider.notifier)
                            .approve(e.id),
                        child: Text(l.tchApprove),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
