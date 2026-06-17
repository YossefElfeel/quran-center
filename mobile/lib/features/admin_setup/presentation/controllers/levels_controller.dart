import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/level_repository.dart';
import '../../domain/level.dart';

part 'levels_controller.g.dart';

/// مستويات منهج معيّن (family بالـ curriculumId) + إضافة.
@riverpod
class LevelsController extends _$LevelsController {
  @override
  Future<List<Level>> build(String curriculumId) {
    return ref.watch(levelRepositoryProvider).fetchByCurriculum(curriculumId);
  }

  Future<void> add(String name) async {
    await ref
        .read(levelRepositoryProvider)
        .add(curriculumId: curriculumId, name: name);
    ref.invalidateSelf();
    await future;
  }
}
