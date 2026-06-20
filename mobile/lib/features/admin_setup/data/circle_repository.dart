import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/circle.dart';
import '../domain/teacher_option.dart';

part 'circle_repository.g.dart';

/// الوصول لبيانات الحلقات + قائمة المعلّمين للإسناد.
class CircleRepository {
  CircleRepository(this._client);

  final SupabaseClient _client;

  Future<List<Circle>> fetchByLevel(String levelId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('circle')
        .select(
          'id, level_id, name, max_size, status, teacher_id, '
          'teacher:teacher_id(full_name)',
        )
        .eq('level_id', levelId)
        .order('created_at', ascending: true)
        .timeout(const Duration(seconds: 12));
    return rows.map(Circle.fromMap).toList();
  }

  /// المعلّمون = الأشخاص اللي عندهم دور teacher.
  Future<List<TeacherOption>> fetchTeachers() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('role_assignment')
        .select('person:person_id(id, full_name)')
        .eq('role', 'teacher')
        .timeout(const Duration(seconds: 12));
    return rows
        .map((Map<String, dynamic> r) {
          final Map<String, dynamic>? p = r['person'] as Map<String, dynamic>?;
          final String? id = p?['id'] as String?;
          if (id == null) return null;
          return TeacherOption(
            id: id,
            fullName: (p?['full_name'] as String?) ?? '—',
          );
        })
        .whereType<TeacherOption>()
        .toList();
  }

  Future<void> add({
    required String levelId,
    required String name,
    required int maxSize,
    String? teacherId,
  }) async {
    await _client.from('circle').insert(<String, dynamic>{
      'level_id': levelId,
      'name': name,
      'max_size': maxSize,
      'teacher_id': ?teacherId,
    });
  }
}

@riverpod
CircleRepository circleRepository(Ref ref) =>
    CircleRepository(ref.watch(supabaseClientProvider));
