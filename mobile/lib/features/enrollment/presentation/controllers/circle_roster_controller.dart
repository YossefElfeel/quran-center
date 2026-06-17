import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enrollment_repository.dart';
import '../../domain/enrolled_student.dart';
import '../../domain/gender.dart';

part 'circle_roster_controller.g.dart';

/// روستر حلقة معيّنة (family بالـ circleId) + إضافة طالب.
@riverpod
class CircleRosterController extends _$CircleRosterController {
  @override
  Future<List<EnrolledStudent>> build(String circleId) {
    return ref.watch(enrollmentRepositoryProvider).fetchByCircle(circleId);
  }

  Future<void> addStudent({
    required String name,
    required Gender gender,
  }) async {
    await ref
        .read(enrollmentRepositoryProvider)
        .addStudent(circleId: circleId, name: name, gender: gender);
    ref.invalidateSelf();
    await future;
  }
}
