import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../admin_setup/domain/circle.dart';
import '../../progress_engine/domain/ledger_state.dart';
import '../domain/portion.dart';
import '../domain/tasmee_kind.dart';
import 'current_cycle.dart';
import 'surah_option.dart';

part 'session_repository.g.dart';

/// بيانات "حصة النهارده": حلقات المعلّم + دورة حياة الحصة + الحضور + التسميع
/// + الانتقال + قفل الحصة بخطة.
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

  // ===== المقطع الحالي + التسميع + الانتقال =====

  /// الدورة المفتوحة للحلقة (المقطع الحالي + المقام المجمّد) أو null.
  Future<CurrentCycle?> currentCycle(String circleId) async {
    final Map<String, dynamic>? row = await _client
        .from('group_portion_cycle')
        .select(
          'id, active_at_open, portion:portion_id'
          '(id, name, surah_start, ayah_start, surah_end, ayah_end)',
        )
        .eq('circle_id', circleId)
        .isFilter('advanced_at', null)
        .maybeSingle();
    if (row == null) return null;
    return CurrentCycle.fromMap(row);
  }

  /// السور المرجعية (لاختيار نطاق المقطع).
  Future<List<SurahOption>> fetchSurahs() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('surah')
        .select('number, name, ayah_count')
        .order('number', ascending: true);
    return rows.map(SurahOption.fromMap).toList();
  }

  /// ينشئ مقطعًا ويرجّع معرّفه.
  Future<String> _insertPortion({
    required String name,
    required int surahStart,
    required int ayahStart,
    required int surahEnd,
    required int ayahEnd,
  }) async {
    final Map<String, dynamic> row = await _client
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
    return row['id'] as String;
  }

  /// عدد التسجيلات الفعّالة دلوقتي (المقام المجمّد عند فتح المقطع).
  Future<int> _activeEnrollmentCount(String circleId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('enrollment')
        .select('id')
        .eq('circle_id', circleId)
        .eq('status', 'active');
    return rows.length;
  }

  /// ينشئ مقطعًا جديدًا ويفتحه كدورة (المقطع الحالي) للحلقة + يجمّد المقام.
  /// لازم يتنده والحلقة مفيهاش دورة مفتوحة (أول مقطع)؛ الانتقال بيستخدم advanceGroup.
  Future<void> setCurrentPortion({
    required String circleId,
    required String name,
    required int surahStart,
    required int ayahStart,
    required int surahEnd,
    required int ayahEnd,
  }) async {
    final String portionId = await _insertPortion(
      name: name,
      surahStart: surahStart,
      ayahStart: ayahStart,
      surahEnd: surahEnd,
      ayahEnd: ayahEnd,
    );
    final int activeAtOpen = await _activeEnrollmentCount(circleId);

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
      'active_at_open': activeAtOpen,
    });
  }

  /// ينقل المجموعة: يقفل الدورة المفتوحة (advanced_at + pass_rate) ثم يفتح
  /// دورة جديدة للمقطع التالي. الترتيب (قفل ثم فتح) بيحترم gpc_one_open.
  Future<void> advanceGroup({
    required String circleId,
    required double passRate,
    required String name,
    required int surahStart,
    required int ayahStart,
    required int surahEnd,
    required int ayahEnd,
  }) async {
    await _client
        .from('group_portion_cycle')
        .update(<String, dynamic>{
          'advanced_at': DateTime.now().toUtc().toIso8601String(),
          'pass_rate': passRate,
        })
        .eq('circle_id', circleId)
        .isFilter('advanced_at', null);
    await setCurrentPortion(
      circleId: circleId,
      name: name,
      surahStart: surahStart,
      ayahStart: ayahStart,
      surahEnd: surahEnd,
      ayahEnd: ayahEnd,
    );
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

  /// يسجّل تسميع عبر دالة السيرفر الذرّية (idempotent + التاريخ من السيرفر)
  /// ويرجّع حالة الدفتر الجديدة.
  Future<LedgerState> recordTasmee({
    required String enrollmentId,
    required String studentPersonId,
    required String portionId,
    required int score,
    required bool passed,
    required String idempotencyKey,
    TasmeeKind kind = TasmeeKind.memorization,
    String? teacherId,
    String? sessionId,
  }) async {
    final dynamic res = await _client.rpc<dynamic>(
      'record_tasmee',
      params: <String, dynamic>{
        'p_enrollment_id': enrollmentId,
        'p_student_person_id': studentPersonId,
        'p_portion_id': portionId,
        'p_score': score,
        'p_passed': passed,
        'p_idempotency_key': idempotencyKey,
        'p_kind': kind.dbValue,
        'p_session_id': sessionId,
        'p_teacher_id': teacherId,
      },
    );
    return LedgerState.fromDb(res as String);
  }

  // ===== المراجعة + قفل الحصة بخطة =====

  /// المراجعة المطلوبة في آخر خطة حصة للحلقة (أو null).
  Future<Portion?> fetchRequiredRevision(String circleId) async {
    final Map<String, dynamic>? row = await _client
        .from('session_plan')
        .select(
          'revision:revision_portion_id'
          '(id, name, surah_start, ayah_start, surah_end, ayah_end)',
        )
        .eq('circle_id', circleId)
        .order('set_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final Object? rev = row?['revision'];
    if (rev == null) return null;
    return Portion.fromMap(rev as Map<String, dynamic>);
  }

  /// يقفل الحصة بخطة: يسجّل خطة المراجعة الجاية + حصيلة الحفظ النهارده ثم يقفل.
  /// الترتيب: الخطة قبل القفل (لو الخطة فشلت مايتقفلش).
  Future<void> closeSessionWithPlan({
    required String circleId,
    required String sessionId,
    String? revisionName,
    int? revSurahStart,
    int? revAyahStart,
    int? revSurahEnd,
    int? revAyahEnd,
    String? memorizedTodayPortionId,
    String? teacherId,
  }) async {
    String? revisionPortionId;
    if (revisionName != null &&
        revSurahStart != null &&
        revAyahStart != null &&
        revSurahEnd != null &&
        revAyahEnd != null) {
      revisionPortionId = await _insertPortion(
        name: revisionName,
        surahStart: revSurahStart,
        ayahStart: revAyahStart,
        surahEnd: revSurahEnd,
        ayahEnd: revAyahEnd,
      );
    }

    // for_session_id متساب null: الخطة للحصة الجاية (لسه متفتحتش)، مش للحالية.
    await _client.from('session_plan').insert(<String, dynamic>{
      'circle_id': circleId,
      'revision_portion_id': ?revisionPortionId,
      'set_by': ?teacherId,
    });

    if (memorizedTodayPortionId != null) {
      await _client.from('session_outcome').insert(<String, dynamic>{
        'session_id': sessionId,
        'memorized_portion_id': memorizedTodayPortionId,
      });
    }

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
