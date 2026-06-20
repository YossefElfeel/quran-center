import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/parent_repository.dart';
import '../../domain/child_history.dart';

part 'child_history_controllers.g.dart';

/// سجلّ تسميع الطفل (حفظ + مراجعة).
@riverpod
Future<List<TasmeeHistoryEntry>> childTasmeeHistory(
  Ref ref,
  String studentPersonId,
) => ref.watch(parentRepositoryProvider).fetchTasmeeHistory(studentPersonId);

/// سجلّ حضور الطفل.
@riverpod
Future<List<AttendanceHistoryEntry>> childAttendanceHistory(
  Ref ref,
  String studentPersonId,
) =>
    ref.watch(parentRepositoryProvider).fetchAttendanceHistory(studentPersonId);
