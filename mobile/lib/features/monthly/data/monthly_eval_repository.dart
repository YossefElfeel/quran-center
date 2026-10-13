import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/monthly_eval.dart';

part 'monthly_eval_repository.g.dart';

/// التقييم الشهري للطالب: المعلّم يملا (submitted) → المشرف يعتمد (approved).
class MonthlyEvalRepository {
  MonthlyEvalRepository(this._client);

  final SupabaseClient _client;

  String _thisMonth() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
  }

  /// طلبة الحلقة + تقييم الشهر الحالي لكل واحد (لو موجود) — للمعلّم.
  Future<List<MonthlyEvalStudent>> fetchCircleEvals(
    String circleId, {
    String? month,
  }) async {
    if (month != null) {
      // A returned historical evaluation stays editable after the student transfers.
      // Filter through enrollment history on the server rather than today's active roster.
      final rows = await _client
          .from('monthly_student_evaluation')
          .select(
            'student_person_id, status, summary, behavior, return_reason, '
            'student:student_person_id!inner(full_name, enrollments:enrollment!inner(circle_id))',
          )
          .eq('month', month)
          .eq('student.enrollments.circle_id', circleId)
          .order('student_person_id')
          .timeout(const Duration(seconds: 12));
      return rows
          .map(
            (row) => MonthlyEvalStudent(
              studentPersonId: row['student_person_id'] as String,
              studentName:
                  (row['student'] as Map<String, dynamic>?)?['full_name']
                      as String? ??
                  '—',
              status: row['status'] as String?,
              summary: row['summary'] as String?,
              behavior: row['behavior'] as String?,
              returnReason: row['return_reason'] as String?,
            ),
          )
          .toList();
    }
    final List<Map<String, dynamic>> enr = await _client
        .from('enrollment')
        .select('student:student_person_id(id, full_name)')
        .eq('circle_id', circleId)
        .eq('status', 'active')
        .timeout(const Duration(seconds: 12));
    final List<Map<String, dynamic>> students = <Map<String, dynamic>>[
      for (final Map<String, dynamic> r in enr)
        if (r['student'] is Map<String, dynamic>)
          r['student'] as Map<String, dynamic>,
    ];
    final List<String> ids = <String>[
      for (final Map<String, dynamic> s in students) s['id'] as String,
    ];
    final List<Map<String, dynamic>> evals = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('monthly_student_evaluation')
              .select(
                'student_person_id, status, summary, behavior, return_reason',
              )
              .eq('month', month ?? _thisMonth())
              .inFilter('student_person_id', ids)
              .timeout(const Duration(seconds: 12));
    final Map<String, Map<String, dynamic>> byStudent =
        <String, Map<String, dynamic>>{
          for (final Map<String, dynamic> e in evals)
            e['student_person_id'] as String: e,
        };
    return students.map((Map<String, dynamic> s) {
      final Map<String, dynamic>? e = byStudent[s['id']];
      return MonthlyEvalStudent(
        studentPersonId: s['id'] as String,
        studentName: s['full_name'] as String,
        status: e?['status'] as String?,
        summary: e?['summary'] as String?,
        behavior: e?['behavior'] as String?,
        returnReason: e?['return_reason'] as String?,
      );
    }).toList();
  }

  Future<void> saveEval({
    required String studentPersonId,
    String? summary,
    String? behavior,
    String? month,
  }) async {
    await _client.from('monthly_student_evaluation').upsert(<String, dynamic>{
      'student_person_id': studentPersonId,
      'month': month ?? _thisMonth(),
      'status': 'submitted',
      'summary': summary,
      'behavior': behavior,
    }, onConflict: 'student_person_id,month');
  }

  /// طابور الاعتماد (submitted) — للمشرف.
  Future<List<PendingMonthlyEval>> fetchPending({int offset = 0}) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('monthly_student_evaluation')
        .select(
          'id, summary, behavior, month, student:student_person_id(full_name)',
        )
        .eq('status', 'submitted')
        .order('month', ascending: false)
        .order('id')
        .range(offset, offset + 49)
        .timeout(const Duration(seconds: 12));
    return rows.map(PendingMonthlyEval.fromMap).toList();
  }

  Future<void> approve(String id) async {
    await _client
        .from('monthly_student_evaluation')
        .update(<String, dynamic>{'status': 'approved'})
        .eq('id', id)
        .eq('status', 'submitted')
        .select('id')
        .single();
  }

  Future<void> returnForRevision(String id, String reason) async {
    await _client
        .from('monthly_student_evaluation')
        .update(<String, dynamic>{
          'status': 'returned',
          'return_reason': reason,
        })
        .eq('id', id)
        .eq('status', 'submitted')
        .select('id')
        .single();
  }
}

@riverpod
MonthlyEvalRepository monthlyEvalRepository(Ref ref) =>
    MonthlyEvalRepository(ref.watch(supabaseClientProvider));
