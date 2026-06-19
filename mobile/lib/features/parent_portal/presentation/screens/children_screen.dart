import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../subscription/presentation/controllers/my_subscription_controller.dart';
import '../../../subscription/presentation/widgets/pay_required_view.dart';
import '../../domain/child_summary.dart';
import '../controllers/my_children_controller.dart';

/// ولي الأمر — أولاده، خلف بوابة الاشتراك (متأخّر → شاشة الدفع).
class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<bool> sub = ref.watch(mySubscriptionActiveProvider);
    return AppScaffold(
      title: l.ppMyChildren,
      body: sub.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.ppSubscriptionCheckError,
          onRetry: () => ref.invalidate(mySubscriptionActiveProvider),
        ),
        data: (bool active) =>
            active ? const _ChildrenList() : const PayRequiredView(),
      ),
    );
  }
}

class _ChildrenList extends ConsumerWidget {
  const _ChildrenList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<ChildSummary>> state = ref.watch(myChildrenProvider);
    return state.when(
      loading: () => const AppListSkeleton(),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.ppChildrenLoadError,
        onRetry: () => ref.invalidate(myChildrenProvider),
      ),
      data: (List<ChildSummary> items) => items.isEmpty
          ? EmptyState(
              message: l.ppNoChildrenLinked,
              icon: Icons.family_restroom,
            )
          : AppRefreshIndicator(
              onRefresh: () async => ref.invalidate(myChildrenProvider),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final ChildSummary c = items[i];
                  return AppListCard(
                    leading: AppAvatar(name: c.fullName, radius: 22),
                    title: c.fullName,
                    onTap: () => context.push(
                      Routes.parentChild(c.studentPersonId, c.fullName),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
