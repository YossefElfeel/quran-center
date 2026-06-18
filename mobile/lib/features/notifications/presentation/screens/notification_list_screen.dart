import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/app_notification.dart';
import '../controllers/notifications_controller.dart';

/// قايمة الإشعارات + تعليم الكل مقروء.
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> state = ref.watch(
      notificationsControllerProvider,
    );
    return AppScaffold(
      title: 'الإشعارات',
      actions: <Widget>[
        IconButton(
          tooltip: 'علّم الكل مقروء',
          icon: const Icon(Icons.done_all),
          onPressed: () =>
              ref.read(notificationsControllerProvider.notifier).markAllRead(),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الإشعارات',
          onRetry: () => ref.invalidate(notificationsControllerProvider),
        ),
        data: (List<AppNotification> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش إشعارات',
                icon: Icons.notifications_none,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final AppNotification n = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      leading: Icon(
                        n.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: n.isRead
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: n.body != null ? Text(n.body!) : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
