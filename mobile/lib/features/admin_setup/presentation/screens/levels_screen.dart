import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/level.dart';
import '../controllers/levels_controller.dart';
import '../widgets/add_level_sheet.dart';
import '../widgets/level_tile.dart';

/// مستويات منهج معيّن — عرض + إضافة + دخول على حلقات المستوى.
class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({
    required this.curriculumId,
    required this.curriculumName,
    super.key,
  });

  final String curriculumId;
  final String curriculumName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Level>> state = ref.watch(
      levelsControllerProvider(curriculumId),
    );
    return AppScaffold(
      title: curriculumName,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext _) =>
              AddLevelSheet(curriculumId: curriculumId),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.admNewLevel),
      ),
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.admLevelsLoadError,
          onRetry: () => ref.invalidate(levelsControllerProvider(curriculumId)),
        ),
        data: (List<Level> items) => items.isEmpty
            ? EmptyState(message: l.admLevelsEmpty)
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => LevelTile(
                  level: items[i],
                  onTap: () =>
                      context.go(Routes.circles(items[i].id, items[i].name)),
                ),
              ),
      ),
    );
  }
}
