import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../enrollment/domain/gender.dart';
import '../../../subscription/presentation/controllers/my_subscription_controller.dart';
import '../../../subscription/presentation/widgets/pay_required_view.dart';
import '../../domain/child_summary.dart';
import '../controllers/my_children_controller.dart';

/// ولي الأمر — أولاده، خلف بوابة الاشتراك (متأخّر → شاشة الدفع).
class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> sub = ref.watch(mySubscriptionActiveProvider);
    return AppScaffold(
      title: 'أولادي',
      body: sub.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نتأكّد من الاشتراك',
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
    final AsyncValue<List<ChildSummary>> state = ref.watch(myChildrenProvider);
    return state.when(
      loading: () => const AppLoader(),
      error: (Object e, StackTrace _) => AppErrorView(
        message: 'مش قادرين نحمّل البيانات',
        onRetry: () => ref.invalidate(myChildrenProvider),
      ),
      data: (List<ChildSummary> items) => items.isEmpty
          ? const EmptyState(
              message: 'لسه مفيش أولاد مربوطين بحسابك',
              icon: Icons.family_restroom,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int i) {
                final ChildSummary c = items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: Icon(
                        c.gender == Gender.female ? Icons.girl : Icons.boy,
                      ),
                    ),
                    title: Text(c.fullName),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go(
                      Routes.parentChild(c.studentPersonId, c.fullName),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
