import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/recognition_repository.dart';
import '../../domain/top_student_row.dart';

/// لوحة الشرف — متفوّقو الشهر لكل حلقة (علني جوّا التطبيق).
class HonorBoardScreen extends ConsumerWidget {
  const HonorBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TopStudentRow>> state = ref.watch(honorBoardProvider);
    return AppScaffold(
      title: 'لوحة الشرف',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل لوحة الشرف',
          onRetry: () => ref.invalidate(honorBoardProvider),
        ),
        data: (List<TopStudentRow> items) => items.isEmpty
            ? const EmptyState(
                message: 'لسه مفيش متفوّقين الشهر ده',
                icon: Icons.emoji_events_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final TopStudentRow t = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.emoji_events,
                        color: AppColors.accent,
                        size: 32,
                      ),
                      title: Text(
                        t.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${t.circleName} — '
                        '${arabicNumber(t.month.month)}/'
                        '${arabicNumber(t.month.year)}'
                        '${t.reason != null ? '\n${t.reason}' : ''}',
                      ),
                      isThreeLine: t.reason != null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
