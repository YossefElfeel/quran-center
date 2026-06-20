import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/notification_repository.dart';
import '../../domain/app_notification.dart';

part 'notifications_controller.g.dart';

/// إشعارات المستخدم الحالي + تعليم الكل مقروء.
@riverpod
class NotificationsController extends _$NotificationsController {
  @override
  Future<List<AppNotification>> build() =>
      ref.watch(notificationRepositoryProvider).fetchMine();

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidateSelf();
    await future;
  }

  /// يعلّم إشعارًا واحدًا مقروءًا — تحديث متفائل فوري (قبل التنقّل لمصدره).
  Future<void> markRead(String id) async {
    final List<AppNotification>? current = state.asData?.value;
    if (current != null) {
      state = AsyncData<List<AppNotification>>(<AppNotification>[
        for (final AppNotification n in current)
          if (n.id == id && !n.isRead)
            n.copyWith(readAt: DateTime.now())
          else
            n,
      ]);
    }
    await ref.read(notificationRepositoryProvider).markRead(id);
  }
}

/// عدد الإشعارات غير المقروءة (للشارة).
@riverpod
Future<int> unreadCount(Ref ref) async {
  final List<AppNotification> list = await ref.watch(
    notificationsControllerProvider.future,
  );
  return list.where((AppNotification n) => !n.isRead).length;
}
