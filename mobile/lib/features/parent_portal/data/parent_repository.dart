import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/child_card.dart';
import '../domain/child_history.dart';
import '../domain/child_summary.dart';
import '../domain/journey_stop.dart';
import '../domain/monthly_plan_view.dart';
import '../domain/parent_comment.dart';

part 'parent_repository.g.dart';

/// بيانات بوابة ولي الأمر: أولاده + كارت متابعة كل طفل (عبر RLS).
class ParentRepository {
  ParentRepository(this._client);

  final SupabaseClient _client;

  /// أولاد ولي الأمر الحالي (RLS بيفلتر روابطه).
  Future<List<ChildSummary>> fetchMyChildren() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('guardian_link')
        .select('student:student_person_id(id, full_name)')
        .timeout(const Duration(seconds: 12));
    return rows
        .map((Map<String, dynamic> r) {
          // الـ embed بيرجع null لو الـ FK فاضي/الصف اتفلتر بالـ RLS/اتحذف.
          final Map<String, dynamic>? s = r['student'] as Map<String, dynamic>?;
          final String? studentId = s?['id'] as String?;
          if (studentId == null) return null;
          return ChildSummary(
            studentPersonId: studentId,
            fullName: (s?['full_name'] as String?) ?? '—',
          );
        })
        .whereType<ChildSummary>()
        .toList();
  }

  /// كارت طفل: الحلقة النشطة + آخر تسميع + ملخّص الحضور.
  Future<ChildCard> fetchChildCard(String studentPersonId) async {
    final Map<String, dynamic>? person = await _client
        .from('person')
        .select('gender')
        .eq('id', studentPersonId)
        .maybeSingle()
        .timeout(const Duration(seconds: 12));
    final bool isGirl = (person?['gender'] as String?) == 'female';

    final Map<String, dynamic>? enr = await _client
        .from('enrollment')
        .select('id, circle:circle_id(name)')
        .eq('student_person_id', studentPersonId)
        .eq('status', 'active')
        .maybeSingle()
        .timeout(const Duration(seconds: 12));
    final String? enrollmentId = enr?['id'] as String?;
    final String? circleName =
        (enr?['circle'] as Map<String, dynamic>?)?['name'] as String?;

    if (enrollmentId == null) {
      return ChildCard(
        present: 0,
        absent: 0,
        excused: 0,
        late: 0,
        isGirl: isGirl,
      );
    }

    // آخر تسميع حفظ (مش مراجعة) — ده مؤشّر التقدّم لولي الأمر.
    final List<Map<String, dynamic>> tasmee = await _client
        .from('daily_tasmee')
        .select('score, passed, portion:portion_id(name)')
        .eq('enrollment_id', enrollmentId)
        .eq('kind', 'memorization')
        .order('attempt_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(1)
        .timeout(const Duration(seconds: 12));
    LatestTasmee? latest;
    if (tasmee.isNotEmpty) {
      final Map<String, dynamic> t = tasmee.first;
      latest = LatestTasmee(
        score: (t['score'] as num).toInt(),
        passed: t['passed'] as bool,
        portionName:
            ((t['portion'] as Map<String, dynamic>?)?['name'] as String?) ?? '',
      );
    }

    final List<Map<String, dynamic>> att = await _client
        .from('attendance')
        .select('status')
        .eq('enrollment_id', enrollmentId)
        .timeout(const Duration(seconds: 12));
    int present = 0, absent = 0, excused = 0, late = 0;
    for (final Map<String, dynamic> a in att) {
      switch (a['status'] as String) {
        case 'present':
          present++;
        case 'absent':
          absent++;
        case 'absent_excused':
          excused++;
        case 'late':
          late++;
      }
    }

    return ChildCard(
      circleName: circleName,
      latestTasmee: latest,
      present: present,
      absent: absent,
      excused: excused,
      late: late,
      isGirl: isGirl,
    );
  }

  /// معرّف التسجيل النشط للطفل (أو null) — أساس سجلّات التسميع/الحضور.
  Future<String?> _activeEnrollmentId(String studentPersonId) async {
    final Map<String, dynamic>? enr = await _client
        .from('enrollment')
        .select('id')
        .eq('student_person_id', studentPersonId)
        .eq('status', 'active')
        .maybeSingle()
        .timeout(const Duration(seconds: 12));
    return enr?['id'] as String?;
  }

  /// سجلّ تسميع الطفل (حفظ + مراجعة) — الأحدث أولًا (RLS بتقصره على وليّه).
  Future<List<TasmeeHistoryEntry>> fetchTasmeeHistory(
    String studentPersonId,
  ) async {
    final String? enrollmentId = await _activeEnrollmentId(studentPersonId);
    if (enrollmentId == null) return const <TasmeeHistoryEntry>[];
    final List<Map<String, dynamic>> rows = await _client
        .from('daily_tasmee')
        .select('attempt_date, score, passed, kind, portion:portion_id(name)')
        .eq('enrollment_id', enrollmentId)
        .order('attempt_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 12));
    return rows.map(TasmeeHistoryEntry.fromMap).toList();
  }

  /// سجلّ حضور الطفل — الأحدث أولًا.
  Future<List<AttendanceHistoryEntry>> fetchAttendanceHistory(
    String studentPersonId,
  ) async {
    final String? enrollmentId = await _activeEnrollmentId(studentPersonId);
    if (enrollmentId == null) return const <AttendanceHistoryEntry>[];
    final List<Map<String, dynamic>> rows = await _client
        .from('attendance')
        .select('status, session:session_id(session_date)')
        .eq('enrollment_id', enrollmentId)
        .order('created_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 12));
    return rows.map(AttendanceHistoryEntry.fromMap).toList();
  }

  /// أنواع موافقة الوسائط النشطة للطفل (photo/video).
  Future<Set<String>> fetchActiveConsents(String studentPersonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('consent_record')
        .select('scope')
        .eq('student_person_id', studentPersonId)
        .isFilter('revoked_at', null)
        .timeout(const Duration(seconds: 12));
    return rows.map((Map<String, dynamic> r) => r['scope'] as String).toSet();
  }

  /// يمنح موافقة وسائط (المانح بيتحدّد سيرفر-سايد).
  Future<void> grantConsent({
    required String studentPersonId,
    required String scope,
  }) async {
    await _client.from('consent_record').insert(<String, dynamic>{
      'student_person_id': studentPersonId,
      'scope': scope,
    });
  }

  /// يسحب موافقة وسائط نشطة (إخفاء فوري عبر RLS).
  Future<void> revokeConsent({
    required String studentPersonId,
    required String scope,
  }) async {
    await _client
        .from('consent_record')
        .update(<String, dynamic>{
          'revoked_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('student_person_id', studentPersonId)
        .eq('scope', scope)
        .isFilter('revoked_at', null);
  }

  /// خطة الشهر الحالي لحلقة الطفل النشطة (لو موجودة).
  Future<MonthlyPlanView?> fetchChildMonthlyPlan(String studentPersonId) async {
    final Map<String, dynamic>? enr = await _client
        .from('enrollment')
        .select('circle_id')
        .eq('student_person_id', studentPersonId)
        .eq('status', 'active')
        .maybeSingle()
        .timeout(const Duration(seconds: 12));
    final String? circleId = enr?['circle_id'] as String?;
    if (circleId == null) return null;
    final DateTime now = DateTime.now();
    final String month =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
    final Map<String, dynamic>? row = await _client
        .from('monthly_study_plan')
        .select('curriculum_plan, teaching_method, portions_ref')
        .eq('circle_id', circleId)
        .eq('month', month)
        .eq('published', true)
        .maybeSingle()
        .timeout(const Duration(seconds: 12));
    if (row == null) return null;
    return MonthlyPlanView.fromMap(row);
  }

  /// رحلة الطالب عبر الحلقات (حق المحفّظ) — الأقدم الأول.
  Future<List<JourneyStop>> fetchChildJourney(String studentPersonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('student_journey_segment')
        .select(
          'from_point, to_point, ajza, pages, ended_at, '
          'circle:circle_id(name), teacher:teacher_id(full_name)',
        )
        .eq('student_person_id', studentPersonId)
        .order('started_at', ascending: true)
        .timeout(const Duration(seconds: 12));
    return rows.map(JourneyStop.fromMap).toList();
  }

  /// تعليقات ولي الأمر على الطفل (الأحدث الأول) + اسم كاتبها.
  Future<List<ParentComment>> fetchComments(String studentPersonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('parent_comment')
        .select('id, body, created_at, author:author_guardian_id(full_name)')
        .eq('student_person_id', studentPersonId)
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 12));
    return rows.map(ParentComment.fromMap).toList();
  }

  /// يضيف تعليق. المؤلّف بيتحدّد سيرفر-سايد (default current_person_id).
  Future<void> addComment({
    required String studentPersonId,
    required String body,
  }) async {
    await _client.from('parent_comment').insert(<String, dynamic>{
      'student_person_id': studentPersonId,
      'body': body,
    });
  }
}

@riverpod
ParentRepository parentRepository(Ref ref) =>
    ParentRepository(ref.watch(supabaseClientProvider));
