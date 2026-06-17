import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../admin_setup/domain/circle.dart';
import '../controllers/my_circles_controller.dart';

/// حلقات المعلّم — يختار حلقة يفتح حصتها.
class MyCirclesScreen extends ConsumerWidget {
  const MyCirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Circle>> state = ref.watch(myCirclesProvider);
    return AppScaffold(
      title: 'حلقاتي',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل حلقاتك',
          onRetry: () => ref.invalidate(myCirclesProvider),
        ),
        data: (List<Circle> items) => items.isEmpty
            ? const EmptyState(
                message: 'لسه مفيش حلقات متسندة لك',
                icon: Icons.groups_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => Card(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: ListTile(
                    leading: const Icon(Icons.groups, color: AppColors.primary),
                    title: Text(items[i].name),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () =>
                        context.go(Routes.session(items[i].id, items[i].name)),
                  ),
                ),
              ),
      ),
    );
  }
}
