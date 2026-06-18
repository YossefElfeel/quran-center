import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/course.dart';

part 'course_repository.g.dart';

/// الكورسات المجانية (قراءة للكل، إدارة للأدمن).
class CourseRepository {
  CourseRepository(this._client);

  final SupabaseClient _client;

  Future<List<Course>> fetchCourses() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('course')
        .select('id, title, video_url, description')
        .order('created_at', ascending: false);
    return rows.map(Course.fromMap).toList();
  }

  Future<void> addCourse({
    required String title,
    required String videoUrl,
    String? description,
  }) async {
    await _client.from('course').insert(<String, dynamic>{
      'title': title,
      'video_url': videoUrl,
      'description': description,
      'is_free': true,
    });
  }
}

@riverpod
CourseRepository courseRepository(Ref ref) =>
    CourseRepository(ref.watch(supabaseClientProvider));
