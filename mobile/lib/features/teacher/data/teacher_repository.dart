import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/teacher_dev_entry.dart';

part 'teacher_repository.g.dart';

/// تطوّر المعلّم + مؤشّر الأداء. (الملف الكامل cv/مؤهّلات للأدمن — مؤجّل UI.)
class TeacherRepository {
  TeacherRepository(this._client);

  final SupabaseClient _client;

  /// تطوّري أنا (RLS بيرجّع بتاعي بس).
  Future<List<TeacherDevEntry>> fetchMyDevelopment() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('teacher_development')
        .select('id, month, status, memorization_progress')
        .order('month', ascending: false);
    return rows.map(TeacherDevEntry.fromMap).toList();
  }

  Future<void> addDevelopment({
    required String teacherPersonId,
    required String month,
    required String progress,
  }) async {
    await _client.from('teacher_development').insert(<String, dynamic>{
      'teacher_person_id': teacherPersonId,
      'month': month,
      'memorization_progress': progress,
      'status': 'submitted',
    });
  }

  /// نسبة نجاح طلبتي (مؤشّر أداء).
  Future<double> myPassRate(String teacherPersonId) async {
    final dynamic res = await _client.rpc(
      'teacher_pass_rate',
      params: <String, dynamic>{'p_teacher': teacherPersonId},
    );
    return (res as num?)?.toDouble() ?? 0;
  }

  /// طابور اعتماد التطوّر (للمشرف).
  Future<List<TeacherDevEntry>> fetchPendingDevelopment() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('teacher_development')
        .select(
          'id, month, status, memorization_progress, '
          'teacher:teacher_person_id(full_name)',
        )
        .eq('status', 'submitted')
        .order('month', ascending: false);
    return rows.map(TeacherDevEntry.fromMap).toList();
  }

  Future<void> approveDevelopment(String id) async {
    await _client
        .from('teacher_development')
        .update(<String, dynamic>{'status': 'approved'})
        .eq('id', id);
  }
}

@riverpod
TeacherRepository teacherRepository(Ref ref) =>
    TeacherRepository(ref.watch(supabaseClientProvider));
