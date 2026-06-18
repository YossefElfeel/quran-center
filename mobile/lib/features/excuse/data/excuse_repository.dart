import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/pending_excuse.dart';

part 'excuse_repository.g.dart';

/// أعذار الغياب: المعلّم يطلب، المشرف يقرّر (الموافقة تخلّي الحضور محايد).
class ExcuseRepository {
  ExcuseRepository(this._client);

  final SupabaseClient _client;

  /// المعلّم يطلب عذر لطالب غايب في الحصة الحالية.
  Future<void> createExcuse({
    required String enrollmentId,
    String? sessionId,
    String? reason,
  }) async {
    await _client.from('excuse_request').insert(<String, dynamic>{
      'enrollment_id': enrollmentId,
      'session_id': ?sessionId,
      'reason': ?reason,
    });
  }

  /// طابور الأعذار المعلّقة (مع اسم الطالب والحلقة).
  Future<List<PendingExcuse>> fetchPending() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('excuse_request')
        .select(
          'id, enrollment_id, session_id, reason, '
          'enrollment:enrollment_id('
          'student:student_person_id(full_name), circle:circle_id(name))',
        )
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return rows.map(PendingExcuse.fromMap).toList();
  }

  /// قرار المشرف: موافقة → الحضور absent_excused (محايد)؛ أو رفض.
  Future<void> decide({
    required String excuseId,
    required bool approve,
    required String enrollmentId,
    String? sessionId,
    String? supervisorId,
  }) async {
    await _client
        .from('excuse_request')
        .update(<String, dynamic>{
          'status': approve ? 'approved' : 'rejected',
          'decided_by': ?supervisorId,
          'decided_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', excuseId);

    if (approve && sessionId != null) {
      await _client.from('attendance').upsert(<String, dynamic>{
        'session_id': sessionId,
        'enrollment_id': enrollmentId,
        'status': 'absent_excused',
        'excuse_approved_by': ?supervisorId,
      }, onConflict: 'session_id,enrollment_id');
    }

    // المشرف بيبلّغ المعلّم بقرار العذر (best-effort — مايوقفش القرار لو فشل).
    try {
      await _notifyTeacher(enrollmentId: enrollmentId, approve: approve);
    } catch (_) {
      // فشل الإشعار مايأثّرش على قرار العذر نفسه.
    }
  }

  Future<void> _notifyTeacher({
    required String enrollmentId,
    required bool approve,
  }) async {
    final Map<String, dynamic>? row = await _client
        .from('enrollment')
        .select(
          'circle:circle_id(teacher_id), '
          'student:student_person_id(full_name)',
        )
        .eq('id', enrollmentId)
        .maybeSingle();
    final Map<String, dynamic>? circle =
        row?['circle'] as Map<String, dynamic>?;
    final String? teacherId = circle?['teacher_id'] as String?;
    if (teacherId == null) return;
    final Map<String, dynamic>? student =
        row?['student'] as Map<String, dynamic>?;
    final String studentName = (student?['full_name'] as String?) ?? 'الطالب';
    await _client.from('notification').insert(<String, dynamic>{
      'recipient_person_id': teacherId,
      'type': 'excuse_decided',
      'title': approve ? 'عذر غياب اتقبل' : 'عذر غياب اترفض',
      'body': 'عذر غياب $studentName ${approve ? 'اتقبل' : 'اترفض'} من المشرف',
    });
  }
}

@riverpod
ExcuseRepository excuseRepository(Ref ref) =>
    ExcuseRepository(ref.watch(supabaseClientProvider));
