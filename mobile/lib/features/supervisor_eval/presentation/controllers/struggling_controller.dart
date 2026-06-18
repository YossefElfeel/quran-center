import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supervisor_eval_repository.dart';
import '../../domain/struggling_student.dart';

part 'struggling_controller.g.dart';

/// الطلبة المتعثّرين (محتاجين انتباه) — عليهم دَيْن وفشلوا مرّات كتير.
@riverpod
Future<List<StrugglingStudent>> strugglingStudents(Ref ref) =>
    ref.watch(supervisorEvalRepositoryProvider).fetchStruggling();
