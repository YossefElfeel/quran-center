import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_approval_actions.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_paged_list.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/teacher_repository.dart';
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
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.tchQueueLoadFailed,
          onRetry: () => ref.invalidate(pendingDevelopmentProvider),
        ),
        data: (List<TeacherDevEntry> items) => items.isEmpty
            ? EmptyState(
                message: l.tchNoPendingApprovals,
                icon: Icons.done_all,
                title: 'كل الطلبات متراجعة',
                action: TextButton(
                  onPressed: () => ref.invalidate(pendingDevelopmentProvider),
                  child: const Text('تحديث الطلبات'),
                ),
              )
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(pendingDevelopmentProvider),
                child: AppPagedList<TeacherDevEntry>(
                  items: items,
                  loadPage: (offset) => ref
                      .read(teacherRepositoryProvider)
                      .fetchPendingDevelopment(offset: offset),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemBuilder:
                      (BuildContext context, TeacherDevEntry e, int i) {
                        return AppListCard(
                          leadingIcon: Icons.person,
                          title: e.teacherName ?? l.tchTeacherFallback,
                          subtitle:
                              '${e.progress ?? '—'}\n'
                              '${arabicNumber(e.month.month)}/'
                              '${arabicNumber(e.month.year)}',
                          trailing: AppApprovalActions(
                            onApprove: () => ref
                                .read(pendingDevelopmentProvider.notifier)
                                .approve(e.id),
                            onReturn: (String reason) => ref
                                .read(pendingDevelopmentProvider.notifier)
                                .returnForRevision(e.id, reason),
                          ),
                        );
                      },
                ),
              ),
      ),
    );
  }
}
