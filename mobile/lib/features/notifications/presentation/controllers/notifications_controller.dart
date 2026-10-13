import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/supabase/supabase_providers.dart';

import '../../data/notification_repository.dart';
import '../../domain/app_notification.dart';

part 'notifications_controller.g.dart';

/// إشعارات المستخدم الحالي + تعليم الكل مقروء.
@riverpod
class NotificationsController extends _$NotificationsController {
  @override
  Future<List<AppNotification>> build() async {
    final String? personId = await ref.watch(currentPersonIdProvider.future);
    if (personId == null) return <AppNotification>[];
    return ref
        .watch(notificationRepositoryProvider)
        .fetchMine(recipientPersonId: personId);
  }

  Future<void> loadMore() async {
    final List<AppNotification>? current = state.asData?.value;
    if (current == null) return;
    final String? personId = await ref.read(currentPersonIdProvider.future);
    final List<AppNotification> page = await ref
        .read(notificationRepositoryProvider)
        .fetchMine(recipientPersonId: personId, offset: current.length);
    state = AsyncData<List<AppNotification>>(<AppNotification>[
      ...current,
      ...page,
    ]);
  }

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
  ref.watch(notificationsControllerProvider);
  final String? personId = await ref.watch(currentPersonIdProvider.future);
  return personId == null
      ? 0
      : ref.watch(notificationRepositoryProvider).unreadCount(personId);
}

final Provider<void> notificationRealtimeProvider = Provider((Ref ref) {
  final String? personId = ref.watch(currentPersonIdProvider).asData?.value;
  if (personId == null) return;
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  final RealtimeChannel channel = client
      .channel('notifications:$personId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notification',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_person_id',
          value: personId,
        ),
        callback: (_) {
          ref.invalidate(notificationsControllerProvider);
          ref.invalidate(unreadCountProvider);
        },
      )
      .subscribe();
  ref.onDispose(() => unawaited(client.removeChannel(channel)));
});
