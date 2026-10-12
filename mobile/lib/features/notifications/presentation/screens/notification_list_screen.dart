import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/utils/arabic_date.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../parent_portal/domain/child_summary.dart';
import '../../../parent_portal/presentation/controllers/my_children_controller.dart';
import '../../domain/app_notification.dart';
import '../../notification_router.dart';
import '../controllers/notifications_controller.dart';

/// قايمة الإشعارات + تعليم الكل مقروء. كل إشعار قابل للنقر → بيروح لمصدره
/// (كارت الطفل/الحلقة/الطابور المناسب) ويتعلّم مقروء.
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  Future<void> _markRead(WidgetRef ref, String id) async {
    try {
      await ref.read(notificationsControllerProvider.notifier).markRead(id);
    } catch (_) {
      ref.invalidate(notificationsControllerProvider);
    }
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
    String? route,
  ) {
    unawaited(_markRead(ref, n.id));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                n.title,
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                arabicDateTimeLabel(n.createdAt),
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: sheetContext.palette.textSecondary,
                ),
              ),
              if (n.body?.trim().isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                SelectableText(n.body!.trim()),
              ],
              if (route != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(context.push(route));
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppL10n.of(sheetContext).notificationOpenSource),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<AppNotification>> state = ref.watch(
      notificationsControllerProvider,
    );
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? const <String>[];
    // أبناء ولي الأمر (للتوجيه المباشر لكارت الطفل) — للأدوار الأبوية بس.
    final List<ChildSummary> children = roles.contains('parent')
        ? (ref.watch(myChildrenProvider).asData?.value ??
              const <ChildSummary>[])
        : const <ChildSummary>[];

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
                  itemBuilder: (BuildContext context, int i) {
                    final AppNotification n = items[i];
                    final String? route = notificationRoute(
                      n,
                      roles,
                      children: children,
                    );
                    return _NotificationTile(
                      key: ValueKey<String>(n.id),
                      notification: n,
                      onTap: () => _open(context, ref, n, route),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// بلاطة إشعار: أيقونة حسب النوع + نقطة للغير مقروء + سهم لو قابل للنقر.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap, super.key});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool read = notification.isRead;
    final Widget trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!read) ...<Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Icon(Icons.chevron_left, color: p.textSecondary),
      ],
    );
    return AppListCard(
      leadingIcon: _iconForType(notification.type),
      iconColor: read ? p.textSecondary : p.primary,
      title: notification.title,
      subtitle: notification.body,
      onTap: onTap,
      trailing: trailing,
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
  'progress_card' => Icons.assignment_turned_in,
  'monthly_eval_missed' => Icons.event_busy,
  'complaint_overdue' => Icons.report_problem,
  'certificate_candidate' => Icons.workspace_premium,
  'subscription_overdue' => Icons.payments,
  _ => Icons.notifications,
};
