import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/app_notification.dart';
import '../controllers/notifications_controller.dart';

/// قايمة الإشعارات + تعليم الكل مقروء.
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<AppNotification>> state = ref.watch(
      notificationsControllerProvider,
    );
    return AppScaffold(
      title: l.notificationsTitle,
      actions: <Widget>[
        IconButton(
          tooltip: l.markAllRead,
          icon: const Icon(Icons.done_all),
          onPressed: () =>
              ref.read(notificationsControllerProvider.notifier).markAllRead(),
        ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.notificationsLoadError,
          onRetry: () => ref.invalidate(notificationsControllerProvider),
        ),
        data: (List<AppNotification> items) => items.isEmpty
            ? EmptyState(
                message: l.noNotifications,
                icon: Icons.notifications_none,
              )
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(notificationsControllerProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) =>
                      _NotificationTile(
                        key: ValueKey<String>(items[i].id),
                        notification: items[i],
                      ),
                ),
              ),
      ),
    );
  }
}

/// بلاطة إشعار: أيقونة حسب النوع + نقطة للغير مقروء.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, super.key});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool read = notification.isRead;
    return AppListCard(
      leadingIcon: _iconForType(notification.type),
      iconColor: read ? p.textSecondary : p.primary,
      title: notification.title,
      subtitle: notification.body,
      trailing: read
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: p.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}

/// أيقونة الإشعار حسب نوعه (يطابق منتِجات الـ triggers سيرفر-سايد).
IconData _iconForType(String type) => switch (type) {
  'supervisor_eval' => Icons.grading,
  'advance' => Icons.arrow_upward,
  'struggling' => Icons.warning_amber,
  'behavior_note' => Icons.sticky_note_2,
  'excuse_decided' => Icons.event_available,
  _ => Icons.notifications,
};
