import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/complaint.dart';
import '../domain/teacher_rating_row.dart';

part 'feedback_repository.g.dart';

/// الشكاوى + تقييم المحفّظ.
class FeedbackRepository {
  FeedbackRepository(this._client);

  final SupabaseClient _client;

  String _thisMonth() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
  }

  Future<void> submitComplaint({
    required String category,
    required String body,
  }) async {
    await _client.from('complaint').insert(<String, dynamic>{
      'category': category,
      'body': body,
    });
  }

  /// شكاويّ أنا (RLS: الكاتب يشوف بتاعته).
  Future<List<Complaint>> fetchMyComplaints() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('complaint')
        .select('id, category, body, status, manager_response, created_at')
        .order('created_at', ascending: false);
    return rows.map(Complaint.fromMap).toList();
  }

  /// صندوق الشكاوى (المدير يشوف الكل).
  Future<List<Complaint>> fetchInbox() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('complaint')
        .select(
          'id, category, body, status, manager_response, created_at, '
          'author:author_person_id(full_name)',
        )
        .order('created_at', ascending: false);
    return rows.map(Complaint.fromMap).toList();
  }

  Future<void> respond(String id, String response) async {
    await _client
        .from('complaint')
        .update(<String, dynamic>{
          'manager_response': response,
          'status': 'answered',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  /// تقييمات المحفّظين (المدير/المشرف يقروا — المعلّم مستبعد عبر RLS).
  Future<List<TeacherRatingRow>> fetchTeacherRatings() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('teacher_rating')
        .select(
          'id, stars, comment, hidden_by_manager, '
          'teacher:teacher_person_id(full_name)',
        )
        .order('teacher_person_id', ascending: true)
        .order('created_at', ascending: false);
    return rows.map(TeacherRatingRow.fromMap).toList();
  }

  /// المدير يخفي/يظهر تقييم (RLS = أدمن).
  Future<void> setRatingHidden(String id, bool hidden) async {
    await _client
        .from('teacher_rating')
        .update(<String, dynamic>{'hidden_by_manager': hidden})
        .eq('id', id);
  }

  /// ولي الأمر يقيّم محفّظ ابنه (بيستنتج المعلّم من حلقة الطفل النشطة).
  /// بيرجّع null لو نجح، أو رسالة خطأ بالعربي (مفيش معلّم / قيّم قبل كده).
  Future<String?> rateChildTeacher({
    required String studentPersonId,
    required int stars,
    String? comment,
  }) async {
    final Map<String, dynamic>? enr = await _client
        .from('enrollment')
        .select('circle:circle_id(teacher_id)')
        .eq('student_person_id', studentPersonId)
        .eq('status', 'active')
        .maybeSingle();
    final String? teacherId =
        (enr?['circle'] as Map<String, dynamic>?)?['teacher_id'] as String?;
    if (teacherId == null) return 'الطفل مش في حلقة بمعلّم دلوقتي';
    try {
      await _client.from('teacher_rating').insert(<String, dynamic>{
        'teacher_person_id': teacherId,
        'period': _thisMonth(),
        'stars': stars,
        'comment': comment,
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return 'قيّمت المحفّظ الشهر ده بالفعل';
      rethrow;
    }
  }
}

@riverpod
FeedbackRepository feedbackRepository(Ref ref) =>
    FeedbackRepository(ref.watch(supabaseClientProvider));
