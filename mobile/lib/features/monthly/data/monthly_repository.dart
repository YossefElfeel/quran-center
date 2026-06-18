import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/monthly_plan.dart';

part 'monthly_repository.g.dart';

/// خطة الشهر للحلقة (المعلّم يؤلّف؛ upsert على الحلقة+الشهر).
class MonthlyRepository {
  MonthlyRepository(this._client);

  final SupabaseClient _client;

  String _thisMonth() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
  }

  Future<MonthlyPlan?> fetchThisMonthPlan(String circleId) async {
    final Map<String, dynamic>? row = await _client
        .from('monthly_study_plan')
        .select('curriculum_plan, teaching_method, portions_ref')
        .eq('circle_id', circleId)
        .eq('month', _thisMonth())
        .maybeSingle();
    return row == null ? null : MonthlyPlan.fromMap(row);
  }

  Future<void> savePlan({
    required String circleId,
    String? curriculumPlan,
    String? teachingMethod,
    String? portionsRef,
  }) async {
    await _client.from('monthly_study_plan').upsert(<String, dynamic>{
      'circle_id': circleId,
      'month': _thisMonth(),
      'curriculum_plan': curriculumPlan,
      'teaching_method': teachingMethod,
      'portions_ref': portionsRef,
      'published': true,
    }, onConflict: 'circle_id,month');
  }
}

@riverpod
MonthlyRepository monthlyRepository(Ref ref) =>
    MonthlyRepository(ref.watch(supabaseClientProvider));
