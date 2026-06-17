import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/level.dart';

part 'level_repository.g.dart';

/// الوصول لبيانات المستويات (RLS: قراءة للمسجّلين، كتابة للأدمن).
class LevelRepository {
  LevelRepository(this._client);

  final SupabaseClient _client;

  Future<List<Level>> fetchByCurriculum(String curriculumId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('level')
        .select('id, curriculum_id, ord, name')
        .eq('curriculum_id', curriculumId)
        .order('ord', ascending: true);
    return rows.map(Level.fromMap).toList();
  }

  /// بيضيف مستوى بترتيب تلقائي = أكبر ترتيب موجود + 1.
  Future<void> add({
    required String curriculumId,
    required String name,
  }) async {
    final List<Map<String, dynamic>> top = await _client
        .from('level')
        .select('ord')
        .eq('curriculum_id', curriculumId)
        .order('ord', ascending: false)
        .limit(1);
    final int nextOrd = top.isEmpty ? 1 : (top.first['ord'] as int) + 1;
    await _client.from('level').insert(<String, dynamic>{
      'curriculum_id': curriculumId,
      'ord': nextOrd,
      'name': name,
    });
  }
}

@riverpod
LevelRepository levelRepository(Ref ref) =>
    LevelRepository(ref.watch(supabaseClientProvider));
