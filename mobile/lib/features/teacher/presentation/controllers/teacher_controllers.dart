import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../data/teacher_repository.dart';
import '../../domain/teacher_dev_entry.dart';

part 'teacher_controllers.g.dart';

String _thisMonth() {
  final DateTime now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-01';
}

/// تطوّري أنا + إضافة قيد (يتسجّل submitted للمشرف يعتمده).
@riverpod
class MyDevelopment extends _$MyDevelopment {
  @override
  Future<List<TeacherDevEntry>> build() =>
      ref.watch(teacherRepositoryProvider).fetchMyDevelopment();

  Future<void> add(String progress) async {
    final String trimmed = progress.trim();
    if (trimmed.isEmpty) return;
    final String? pid = await ref.read(currentPersonIdProvider.future);
    if (pid == null) return;
    await ref
        .read(teacherRepositoryProvider)
        .addDevelopment(
          teacherPersonId: pid,
          month: _thisMonth(),
          progress: trimmed,
        );
    ref.invalidateSelf();
    await future;
  }
}

/// نسبة نجاح طلبتي (مؤشّر أداء).
@riverpod
Future<double> myPassRate(Ref ref) async {
  final String? pid = await ref.watch(currentPersonIdProvider.future);
  if (pid == null) return 0;
  return ref.watch(teacherRepositoryProvider).myPassRate(pid);
}

/// طابور اعتماد التطوّر (للمشرف) + اعتماد.
@riverpod
class PendingDevelopment extends _$PendingDevelopment {
  @override
  Future<List<TeacherDevEntry>> build() =>
      ref.watch(teacherRepositoryProvider).fetchPendingDevelopment();

  Future<void> approve(String id) async {
    await ref.read(teacherRepositoryProvider).approveDevelopment(id);
    ref.invalidateSelf();
    await future;
  }
}
