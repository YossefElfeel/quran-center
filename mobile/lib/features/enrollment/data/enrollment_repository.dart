import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/enrolled_student.dart';
import '../domain/gender.dart';

part 'enrollment_repository.g.dart';

/// تسجيل الطلبة في الحلقات (RLS: قراءة للطاقم/المعلّم/ولي الأمر، كتابة للطاقم).
class EnrollmentRepository {
  EnrollmentRepository(this._client);

  final SupabaseClient _client;

  Future<List<EnrolledStudent>> fetchByCircle(String circleId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('enrollment')
        .select('id, status, student:student_person_id(id, full_name, gender)')
        .eq('circle_id', circleId)
        .eq('status', 'active')
        .order('enrolled_at', ascending: true)
        .timeout(const Duration(seconds: 12));
    return rows
        .map(EnrolledStudent.fromMap)
        .whereType<EnrolledStudent>()
        .toList();
  }

  /// بينشئ طالب جديد ويسجّله في الحلقة + يضبط الرقم القومي (اختياري) في معاملة
  /// واحدة ذرّية عبر RPC `enroll_student` — لو الرقم مكرّر/غلط كله بيترجع (مفيش
  /// طالب يتيم).
  Future<void> addStudent({
    required String circleId,
    required String name,
    required Gender gender,
    String? nationalId,
  }) async {
    try {
      await _client.rpc<void>(
        'enroll_student',
        params: <String, dynamic>{
          'p_circle': circleId,
          'p_name': name,
          'p_gender': gender.dbValue,
          'p_national_id': (nationalId == null || nationalId.isEmpty)
              ? null
              : nationalId,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException(
          'الرقم القومي ده مسجّل قبل كده لشخص تاني',
        );
      }
      if (e.code == '22023') {
        throw const ValidationException('الرقم القومي لازم يكون ١٤ رقم');
      }
      rethrow;
    }
  }
}

@riverpod
EnrollmentRepository enrollmentRepository(Ref ref) =>
    EnrollmentRepository(ref.watch(supabaseClientProvider));
