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
        .order('enrolled_at', ascending: true);
    return rows.map(EnrolledStudent.fromMap).toList();
  }

  /// بينشئ طالب جديد (person) ويسجّله في الحلقة (enrollment نشط)، وبيضبط الرقم
  /// القومي (اختياري) عبر RPC آمن (HMAC + تشفير سيرفر-سايد).
  /// ملاحظة: خطوات متتالية؛ الأتمية الكاملة ممكن تتعمل RPC واحدة لاحقًا.
  Future<void> addStudent({
    required String circleId,
    required String name,
    required Gender gender,
    String? nationalId,
  }) async {
    final Map<String, dynamic> person = await _client
        .from('person')
        .insert(<String, dynamic>{
          'full_name': name,
          'gender': gender.dbValue,
          'is_minor': true,
        })
        .select('id')
        .single();
    final String personId = person['id'] as String;
    await _client.from('enrollment').insert(<String, dynamic>{
      'student_person_id': personId,
      'circle_id': circleId,
      'status': 'active',
    });
    if (nationalId != null && nationalId.isNotEmpty) {
      try {
        await _client.rpc<void>(
          'set_person_national_id',
          params: <String, dynamic>{'p_person': personId, 'p_raw': nationalId},
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
}

@riverpod
EnrollmentRepository enrollmentRepository(Ref ref) =>
    EnrollmentRepository(ref.watch(supabaseClientProvider));
