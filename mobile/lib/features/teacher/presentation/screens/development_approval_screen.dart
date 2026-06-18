import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final AsyncValue<List<TeacherDevEntry>> state = ref.watch(
      pendingDevelopmentProvider,
    );
    return AppScaffold(
      title: 'تطوّر المعلّمين',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الطابور',
          onRetry: () => ref.invalidate(pendingDevelopmentProvider),
        ),
        data: (List<TeacherDevEntry> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش طلبات اعتماد دلوقتي',
                icon: Icons.done_all,
              )
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
                      title: Text(e.teacherName ?? 'معلّم'),
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
