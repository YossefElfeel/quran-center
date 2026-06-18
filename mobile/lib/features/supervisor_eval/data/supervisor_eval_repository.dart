import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../admin_setup/domain/circle.dart';
import '../domain/circle_pass_rate.dart';
import '../domain/eval_criterion.dart';
import '../domain/eval_student.dart';
import '../domain/struggling_student.dart';

part 'supervisor_eval_repository.g.dart';

/// بيانات تقييم المشرف: الحلقات + طلبتها + إنشاء تقييم + حفظ الدرجات.
class SupervisorEvalRepository {
  SupervisorEvalRepository(this._client);

  final SupabaseClient _client;

  /// كل الحلقات (المشرف بيشوفها كلها عبر RLS).
  Future<List<Circle>> fetchAllCircles() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('circle')
        .select('id, level_id, name, max_size, status, teacher_id')
        .order('created_at', ascending: true);
    return rows.map(Circle.fromMap).toList();
  }

  Future<List<EvalStudent>> fetchStudents(String circleId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('enrollment')
        .select('student_person_id, student:student_person_id(full_name)')
        .eq('circle_id', circleId)
        .eq('status', 'active')
        .order('enrolled_at', ascending: true);
    return rows.map((Map<String, dynamic> r) {
      final Map<String, dynamic> s = r['student'] as Map<String, dynamic>;
      return EvalStudent(
        studentPersonId: r['student_person_id'] as String,
        fullName: s['full_name'] as String,
      );
    }).toList();
  }

  Future<String> createEvaluation({
    required String circleId,
    required String selection,
    String? supervisorId,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('supervisor_evaluation')
        .insert(<String, dynamic>{
          'circle_id': circleId,
          'selection': selection,
          'supervisor_id': ?supervisorId,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// يحفظ درجات المعايير الـ٣ لطالب داخل تقييم.
  Future<void> saveScores({
    required String evaluationId,
    required String studentPersonId,
    required Map<EvalCriterion, int> scores,
  }) async {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
      for (final MapEntry<EvalCriterion, int> e in scores.entries)
        <String, dynamic>{
          'evaluation_id': evaluationId,
          'student_person_id': studentPersonId,
          'criterion': e.key.dbValue,
          'score': e.value,
        },
    ];
    await _client.from('eval_score').insert(rows);
  }

  /// الطلبة المتعثّرين: عليهم دَيْن وعدد محاولاتهم وصل حد التعثّر أو أكتر.
  /// [threshold] بييجي من إعدادات النظام (struggle_failed_attempts).
  Future<List<StrugglingStudent>> fetchStruggling(int threshold) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('portion_ledger_entry')
        .select(
          'attempts_count, '
          'student:student_person_id(full_name), portion:portion_id(name)',
        )
        .eq('state', 'failed_retry')
        .gte('attempts_count', threshold)
        .order('attempts_count', ascending: false);
    return rows.map(StrugglingStudent.fromMap).toList();
  }

  /// نِسَب نجاح كل حلقة على مقطعها الحالي (عبر دالة السيرفر التجميعية).
  Future<List<CirclePassRate>> fetchCirclePassRates() async {
    final dynamic res = await _client.rpc('circle_pass_rates');
    final List<dynamic> rows = res as List<dynamic>;
    return rows
        .map((dynamic r) => CirclePassRate.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}

@riverpod
SupervisorEvalRepository supervisorEvalRepository(Ref ref) =>
    SupervisorEvalRepository(ref.watch(supabaseClientProvider));
