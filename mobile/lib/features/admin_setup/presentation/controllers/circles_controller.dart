import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/circle_repository.dart';
import '../../domain/circle.dart';
import '../../domain/teacher_option.dart';

part 'circles_controller.g.dart';

/// قائمة المعلّمين المتاحين للإسناد.
@riverpod
Future<List<TeacherOption>> teacherOptions(Ref ref) =>
    ref.watch(circleRepositoryProvider).fetchTeachers();

/// حلقات مستوى معيّن (family بالـ levelId) + إضافة.
@riverpod
class CirclesController extends _$CirclesController {
  @override
  Future<List<Circle>> build(String levelId) {
    return ref.watch(circleRepositoryProvider).fetchByLevel(levelId);
  }

  Future<void> add({
    required String name,
    required int maxSize,
    String? teacherId,
  }) async {
    await ref
        .read(circleRepositoryProvider)
        .add(
          levelId: levelId,
          name: name,
          maxSize: maxSize,
          teacherId: teacherId,
        );
    ref.invalidateSelf();
    await future;
  }
}
