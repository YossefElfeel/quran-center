import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/curriculum.dart';
import '../controllers/curricula_controller.dart';
import '../widgets/add_curriculum_sheet.dart';
import '../widgets/curriculum_tile.dart';

/// شاشة إدارة المناهج (للأدمن) — عرض + إضافة.
class CurriculaScreen extends ConsumerWidget {
  const CurriculaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Curriculum>> state =
        ref.watch(curriculaControllerProvider);
    return AppScaffold(
      title: 'المناهج',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext _) => const AddCurriculumSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('منهج جديد'),
      ),
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل المناهج',
          onRetry: () => ref.invalidate(curriculaControllerProvider),
        ),
        data: (List<Curriculum> items) => items.isEmpty
            ? const EmptyState(message: 'مفيش مناهج لسه — ضيف أول منهج')
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) =>
                    CurriculumTile(curriculum: items[i]),
              ),
      ),
    );
  }
}
