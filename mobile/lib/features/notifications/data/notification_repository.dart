import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/app_notification.dart';

part 'notification_repository.g.dart';

/// الإشعارات: قراءة بتاعتي (عبر RLS) + تعليم مقروء + توصيل (للطاقم).
class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchMine() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('notification')
        .select('id, type, title, body, read_at, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markAllRead() async {
    await _client
        .from('notification')
        .update(<String, dynamic>{
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .isFilter('read_at', null);
  }

  /// يوصّل إشعار لشخص (الطاقم بيبعت).
  Future<void> notify({
    required String recipientPersonId,
    required String type,
    required String title,
    String? body,
  }) async {
    await _client.from('notification').insert(<String, dynamic>{
      'recipient_person_id': recipientPersonId,
      'type': type,
      'title': title,
      'body': ?body,
    });
  }
}

@riverpod
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository(ref.watch(supabaseClientProvider));
