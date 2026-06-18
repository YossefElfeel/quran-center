import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/top_student_row.dart';

part 'recognition_repository.g.dart';

/// لوحة الشرف: متفوّق الشهر لكل حلقة (قراءة للكل، اختيار للمعلّم/المشرف).
class RecognitionRepository {
  RecognitionRepository(this._client);

  final SupabaseClient _client;

  String _thisMonth() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
  }

  Future<List<TopStudentRow>> fetchHonorBoard() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('monthly_top_student')
        .select(
          'month, reason, '
          'circle:circle_id(name), student:student_person_id(full_name)',
        )
        .order('month', ascending: false)
        .limit(50);
    return rows.map(TopStudentRow.fromMap).toList();
  }

  /// يختار متفوّق الشهر لحلقة (upsert على الحلقة+الشهر).
  Future<void> pickTopStudent({
    required String circleId,
    required String studentPersonId,
    String? reason,
  }) async {
    await _client.from('monthly_top_student').upsert(<String, dynamic>{
      'circle_id': circleId,
      'month': _thisMonth(),
      'student_person_id': studentPersonId,
      'reason': reason,
    }, onConflict: 'circle_id,month');
  }
}

@riverpod
RecognitionRepository recognitionRepository(Ref ref) =>
    RecognitionRepository(ref.watch(supabaseClientProvider));

/// لوحة الشرف (متفوّقو الشهر) — يقراها الكل.
@riverpod
Future<List<TopStudentRow>> honorBoard(Ref ref) =>
    ref.watch(recognitionRepositoryProvider).fetchHonorBoard();
