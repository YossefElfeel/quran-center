import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/family_repository.dart';
import '../../domain/student_option.dart';

part 'students_for_link_controller.g.dart';

/// الطلبة المسجّلين (لاختيار الطفل عند الربط).
@riverpod
Future<List<StudentOption>> studentsForLink(Ref ref) =>
    ref.watch(familyRepositoryProvider).fetchStudents();
