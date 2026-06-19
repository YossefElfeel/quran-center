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
import '../../domain/circle.dart';
import '../controllers/circles_controller.dart';
import '../widgets/add_circle_sheet.dart';
import '../widgets/circle_tile.dart';

/// حلقات مستوى معيّن — عرض + إضافة + إسناد معلّم.
class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({
    required this.levelId,
    required this.levelName,
    super.key,
  });

  final String levelId;
  final String levelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Circle>> state = ref.watch(
      circlesControllerProvider(levelId),
    );
    return AppScaffold(
      title: levelName,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext _) => AddCircleSheet(levelId: levelId),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.admNewCircle),
      ),
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.admCirclesLoadError,
          onRetry: () => ref.invalidate(circlesControllerProvider(levelId)),
        ),
        data: (List<Circle> items) => items.isEmpty
            ? EmptyState(message: l.admCirclesEmpty)
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(circlesControllerProvider(levelId)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) => CircleTile(
                    circle: items[i],
                    onTap: () =>
                        context.push(Routes.roster(items[i].id, items[i].name)),
                  ),
                ),
              ),
      ),
    );
  }
}
