import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../admin_setup/domain/circle.dart';
import '../../progress_engine/domain/ledger_state.dart';
import '../../progress_engine/domain/progress_engine.dart';
import '../domain/portion.dart';
import 'surah_option.dart';

part 'session_repository.g.dart';

/// بيانات "حصة النهارده": حلقات المعلّم + دورة حياة الحصة + الحضور + التسميع.
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
        .select(
          'id, student_person_id, student:student_person_id(full_name, gender)',
        )
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
    await _client.from('attendance').upsert(<String, dynamic>{
      'session_id': sessionId,
      'enrollment_id': enrollmentId,
      'status': status,
    }, onConflict: 'session_id,enrollment_id');
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

  // ===== المقطع الحالي + التسميع =====

  /// المقطع الحالي للحلقة (الدورة المفتوحة) أو null لو لسه ماتحدّدش.
  Future<Portion?> currentPortion(String circleId) async {
    final Map<String, dynamic>? row = await _client
        .from('group_portion_cycle')
        .select(
          'portion:portion_id'
          '(id, name, surah_start, ayah_start, surah_end, ayah_end)',
        )
        .eq('circle_id', circleId)
        .isFilter('advanced_at', null)
        .maybeSingle();
    if (row == null) return null;
    return Portion.fromMap(row['portion'] as Map<String, dynamic>);
  }

  /// السور المرجعية (لاختيار نطاق المقطع).
  Future<List<SurahOption>> fetchSurahs() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('surah')
        .select('number, name, ayah_count')
        .order('number', ascending: true);
    return rows.map(SurahOption.fromMap).toList();
  }

  /// ينشئ مقطعًا جديدًا ويفتحه كدورة (المقطع الحالي) للحلقة.
  Future<void> setCurrentPortion({
    required String circleId,
    required String name,
    required int surahStart,
    required int ayahStart,
    required int surahEnd,
    required int ayahEnd,
  }) async {
    final Map<String, dynamic> portion = await _client
        .from('portion')
        .insert(<String, dynamic>{
          'name': name,
          'surah_start': surahStart,
          'ayah_start': ayahStart,
          'surah_end': surahEnd,
          'ayah_end': ayahEnd,
        })
        .select('id')
        .single();
    final String portionId = portion['id'] as String;

    final Map<String, dynamic>? last = await _client
        .from('group_portion_cycle')
        .select('ord')
        .eq('circle_id', circleId)
        .order('ord', ascending: false)
        .limit(1)
        .maybeSingle();
    final int nextOrd = ((last?['ord'] as int?) ?? 0) + 1;

    await _client.from('group_portion_cycle').insert(<String, dynamic>{
      'circle_id': circleId,
      'portion_id': portionId,
      'ord': nextOrd,
    });
  }

  /// حالات الدَيْن لمجموعة طلبة على مقطع معيّن.
  Future<Map<String, LedgerState>> fetchLedger(
    String portionId,
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty) return const <String, LedgerState>{};
    final List<Map<String, dynamic>> rows = await _client
        .from('portion_ledger_entry')
        .select('student_person_id, state')
        .eq('portion_id', portionId)
        .inFilter('student_person_id', studentIds);
    return <String, LedgerState>{
      for (final Map<String, dynamic> r in rows)
        r['student_person_id'] as String: LedgerState.fromDb(
          r['state'] as String,
        ),
    };
  }

  /// يسجّل محاولة تسميع (تتحفظ كلها) + يحدّث دفتر الدَيْن، ويرجّع الحالة الجديدة.
  Future<LedgerState> recordTasmee({
    required String enrollmentId,
    required String studentPersonId,
    required String portionId,
    required int score,
    required bool passed,
    required String idempotencyKey,
    String? teacherId,
    String? sessionId,
  }) async {
    await _client.from('daily_tasmee').insert(<String, dynamic>{
      'enrollment_id': enrollmentId,
      'portion_id': portionId,
      'score': score,
      'passed': passed,
      'idempotency_key': idempotencyKey,
      'teacher_id': ?teacherId,
      'session_id': ?sessionId,
    });

    final Map<String, dynamic>? existing = await _client
        .from('portion_ledger_entry')
        .select('state, attempts_count, passed_on')
        .eq('student_person_id', studentPersonId)
        .eq('portion_id', portionId)
        .maybeSingle();

    final LedgerState current = LedgerState.fromDb(
      (existing?['state'] as String?) ?? 'assigned',
    );
    final LedgerState next = ProgressEngine.nextLedgerState(
      current: current,
      passed: passed,
    );
    final int attempts = ((existing?['attempts_count'] as int?) ?? 0) + 1;
    final String? passedOn = next == LedgerState.passed
        ? ((existing?['passed_on'] as String?) ?? _utcToday())
        : null;

    await _client.from('portion_ledger_entry').upsert(<String, dynamic>{
      'student_person_id': studentPersonId,
      'portion_id': portionId,
      'state': next.dbValue,
      'attempts_count': attempts,
      'passed_on': passedOn,
    }, onConflict: 'student_person_id,portion_id');

    return next;
  }

  static String _utcToday() =>
      DateTime.now().toUtc().toIso8601String().substring(0, 10);
}

@riverpod
SessionRepository sessionRepository(Ref ref) =>
    SessionRepository(ref.watch(supabaseClientProvider));
