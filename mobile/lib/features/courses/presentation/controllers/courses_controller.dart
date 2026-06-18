import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/course_repository.dart';
import '../../domain/course.dart';

part 'courses_controller.g.dart';

/// مكتبة الكورسات + إضافة (أدمن).
@riverpod
class Courses extends _$Courses {
  @override
  Future<List<Course>> build() =>
      ref.watch(courseRepositoryProvider).fetchCourses();

  Future<void> add({
    required String title,
    required String videoUrl,
    String? description,
  }) async {
    if (title.trim().isEmpty || videoUrl.trim().isEmpty) return;
    await ref
        .read(courseRepositoryProvider)
        .addCourse(
          title: title.trim(),
          videoUrl: videoUrl.trim(),
          description: description?.trim(),
        );
    ref.invalidateSelf();
    await future;
  }
}
