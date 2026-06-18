import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/settings/settings_repository.dart';
import '../../data/supervisor_eval_repository.dart';
import '../../domain/struggling_student.dart';

part 'struggling_controller.g.dart';

/// الطلبة المتعثّرين (محتاجين انتباه) — حد التعثّر من إعدادات النظام.
@riverpod
Future<List<StrugglingStudent>> strugglingStudents(Ref ref) async {
  final int threshold = (await ref.watch(
    appSettingsProvider.future,
  )).struggleThreshold;
  return ref.watch(supervisorEvalRepositoryProvider).fetchStruggling(threshold);
}
