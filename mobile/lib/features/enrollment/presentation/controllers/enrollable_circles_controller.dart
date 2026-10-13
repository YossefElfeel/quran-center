import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enrollment_repository.dart';
import '../../domain/enrollable_circle.dart';

part 'enrollable_circles_controller.g.dart';

/// الحلقات اللي ينفع نسجّل فيها طالب (لاختيار الحلقة في مسار التسجيل).
@riverpod
Future<List<EnrollableCircle>> enrollableCircles(Ref ref) =>
    ref.watch(enrollmentRepositoryProvider).fetchEnrollableCircles();
