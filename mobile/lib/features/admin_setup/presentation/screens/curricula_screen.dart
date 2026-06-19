import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
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
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Curriculum>> state = ref.watch(
      curriculaControllerProvider,
    );
    return AppScaffold(
      title: l.admCurriculaTitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext _) => const AddCurriculumSheet(),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.admNewCurriculum),
      ),
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.admCurriculaLoadError,
          onRetry: () => ref.invalidate(curriculaControllerProvider),
        ),
        data: (List<Curriculum> items) => items.isEmpty
            ? EmptyState(message: l.admCurriculaEmpty)
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(curriculaControllerProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) => CurriculumTile(
                    curriculum: items[i],
                    onTap: () =>
                        context.push(Routes.levels(items[i].id, items[i].name)),
                  ),
                ),
              ),
      ),
    );
  }
}
