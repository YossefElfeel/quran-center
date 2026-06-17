import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../admin_setup/domain/circle.dart';

part 'session_repository.g.dart';

/// بيانات "حصة النهارده": حلقات المعلّم + دورة حياة الحصة + الحضور.
class SessionRepository {
  SessionRepository(this._client);

  final SupabaseClient _client;

  Future<List<Circle>> fetchMyCircles(String teacherPersonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('circle')
        .select('id, level_id, name, max_size, status, teacher_id')
        .eq('teacher_id', teacherPersonId)
        .order('created_at', ascending: true);
    return rows.map(Circle.fromMap).toList();
  }

  /// معرّف الحصة المفتوحة للحلقة (أو null).
  Future<String?> openSessionId(String circleId) async {
    final Map<String, dynamic>? row = await _client
        .from('circle_session')
        .select('id')
        .eq('circle_id', circleId)
        .eq('status', 'open')
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<String> openSession(String circleId, String? openedBy) async {
    final Map<String, dynamic> row = await _client
        .from('circle_session')
        .insert(<String, dynamic>{
          'circle_id': circleId,
          'status': 'open',
          'opened_by': ?openedBy,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchRoster(String circleId) async {
    return _client
        .from('enrollment')
        .select('id, student:student_person_id(full_name, gender)')
        .eq('circle_id', circleId)
        .eq('status', 'active')
        .order('enrolled_at', ascending: true);
  }

  Future<Map<String, String>> fetchAttendance(String sessionId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('attendance')
        .select('enrollment_id, status')
        .eq('session_id', sessionId);
    return <String, String>{
      for (final Map<String, dynamic> r in rows)
        r['enrollment_id'] as String: r['status'] as String,
    };
  }

  Future<void> setAttendance({
    required String sessionId,
    required String enrollmentId,
    required String status,
  }) async {
    await _client.from('attendance').upsert(
      <String, dynamic>{
        'session_id': sessionId,
        'enrollment_id': enrollmentId,
        'status': status,
      },
      onConflict: 'session_id,enrollment_id',
    );
  }

  Future<void> closeSession(String sessionId) async {
    await _client
        .from('circle_session')
        .update(<String, dynamic>{
          'status': 'closed',
          'closed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId);
  }
}

@riverpod
SessionRepository sessionRepository(Ref ref) =>
    SessionRepository(ref.watch(supabaseClientProvider));
