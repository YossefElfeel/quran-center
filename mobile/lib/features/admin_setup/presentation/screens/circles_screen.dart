import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
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
        label: const Text('حلقة جديدة'),
      ),
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الحلقات',
          onRetry: () => ref.invalidate(circlesControllerProvider(levelId)),
        ),
        data: (List<Circle> items) => items.isEmpty
            ? const EmptyState(message: 'مفيش حلقات لسه — ضيف أول حلقة')
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => CircleTile(
                  circle: items[i],
                  onTap: () =>
                      context.go(Routes.roster(items[i].id, items[i].name)),
                ),
              ),
      ),
    );
  }
}
