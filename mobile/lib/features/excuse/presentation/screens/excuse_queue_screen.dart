import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/pending_excuse.dart';
import '../controllers/pending_excuses_controller.dart';
import '../widgets/excuse_decision_tile.dart';

/// طابور المشرف: أعذار الغياب المستنية موافقة.
class ExcuseQueueScreen extends ConsumerWidget {
  const ExcuseQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PendingExcuse>> state = ref.watch(
      pendingExcusesControllerProvider,
    );
    return AppScaffold(
      title: 'أعذار الغياب',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الأعذار',
          onRetry: () => ref.invalidate(pendingExcusesControllerProvider),
        ),
        data: (List<PendingExcuse> items) {
          if (items.isEmpty) {
            return const EmptyState(
              message: 'مفيش أعذار مستنية',
              icon: Icons.event_available,
            );
          }
          final PendingExcusesController notifier = ref.read(
            pendingExcusesControllerProvider.notifier,
          );
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int i) => ExcuseDecisionTile(
              key: ValueKey<String>(items[i].id),
              excuse: items[i],
              onApprove: () => notifier.decide(items[i], approve: true),
              onReject: () => notifier.decide(items[i], approve: false),
            ),
          );
        },
      ),
    );
  }
}
