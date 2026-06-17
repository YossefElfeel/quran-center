import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/curriculum_repository.dart';
import '../../domain/curriculum.dart';

part 'curricula_controller.g.dart';

/// قائمة المناهج + إضافة منهج. AsyncNotifier بيعيد التحميل بعد الإضافة.
@riverpod
class CurriculaController extends _$CurriculaController {
  @override
  Future<List<Curriculum>> build() {
    return ref.watch(curriculumRepositoryProvider).fetchAll();
  }

  Future<void> add({required String name, required CurriculumType type}) async {
    await ref.read(curriculumRepositoryProvider).add(name: name, type: type);
    ref.invalidateSelf();
    await future;
  }
}
