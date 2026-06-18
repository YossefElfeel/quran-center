import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../admin_setup/domain/circle.dart';
import '../../data/supervisor_eval_repository.dart';

part 'eval_circles_controller.g.dart';

/// كل الحلقات المتاحة للمشرف عشان يقيّم.
@riverpod
Future<List<Circle>> evalCircles(Ref ref) =>
    ref.watch(supervisorEvalRepositoryProvider).fetchAllCircles();
