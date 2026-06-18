import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/struggling_student.dart';
import '../controllers/struggling_controller.dart';

/// "محتاج انتباه" — الطلبة المتعثّرين على مقاطعهم (دَيْن + محاولات كتير).
class AttentionScreen extends ConsumerWidget {
  const AttentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<StrugglingStudent>> state = ref.watch(
      strugglingStudentsProvider,
    );
    return AppScaffold(
      title: 'محتاج انتباه',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل القايمة',
          onRetry: () => ref.invalidate(strugglingStudentsProvider),
        ),
        data: (List<StrugglingStudent> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش طلبة متعثّرين دلوقتي',
                icon: Icons.sentiment_satisfied_alt,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final StrugglingStudent s = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: ListTile(
                      leading: const Icon(
                        Icons.warning_amber,
                        color: AppColors.error,
                      ),
                      title: Text(s.studentName),
                      subtitle: Text(
                        'عليه دَيْن على ${s.portionName} — '
                        'حاول ${arabicNumber(s.attempts)} مرّات',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
