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
import '../../../admin_setup/domain/circle.dart';
import '../controllers/eval_circles_controller.dart';

/// المشرف يختار حلقة عشان يقيّم طلبتها.
class EvalCirclesScreen extends ConsumerWidget {
  const EvalCirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Circle>> state = ref.watch(evalCirclesProvider);
    return AppScaffold(
      title: l.navEvalCircles,
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.supCirclesLoadError,
          onRetry: () => ref.invalidate(evalCirclesProvider),
        ),
        data: (List<Circle> items) => items.isEmpty
            ? EmptyState(message: l.supNoCircles, icon: Icons.groups_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => Card(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: ListTile(
                    leading: const Icon(
                      Icons.fact_check,
                      color: AppColors.primary,
                    ),
                    title: Text(items[i].name),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go(
                      Routes.supervisorCircleEval(items[i].id, items[i].name),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
