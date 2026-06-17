import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/curriculum.dart';

part 'curriculum_repository.g.dart';

/// الوصول لبيانات المناهج عبر Supabase (RLS: قراءة للمسجّلين، كتابة للأدمن).
class CurriculumRepository {
  CurriculumRepository(this._client);

  final SupabaseClient _client;

  Future<List<Curriculum>> fetchAll() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('curriculum')
        .select('id, name, type, created_at')
        .order('created_at', ascending: true);
    return rows.map(Curriculum.fromMap).toList();
  }

  Future<void> add({
    required String name,
    required CurriculumType type,
  }) async {
    await _client.from('curriculum').insert(<String, dynamic>{
      'name': name,
      'type': type.dbValue,
    });
  }
}

@riverpod
CurriculumRepository curriculumRepository(Ref ref) =>
    CurriculumRepository(ref.watch(supabaseClientProvider));
