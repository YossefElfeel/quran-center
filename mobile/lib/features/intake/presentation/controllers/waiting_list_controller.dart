import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../enrollment/domain/gender.dart';
import '../../data/intake_repository.dart';
import '../../domain/circle_option.dart';
import '../../domain/level_option.dart';
import '../../domain/waiting_applicant.dart';

part 'waiting_list_controller.g.dart';

/// كل المستويات (لقوائم الاختيار: المستهدف + نتيجة الاختبار).
@riverpod
Future<List<LevelOption>> levelOptions(Ref ref) =>
    ref.watch(intakeRepositoryProvider).fetchLevelOptions();

/// حلقات مستوى معيّن (لاختيار حلقة الإسناد).
@riverpod
Future<List<CircleOption>> circlesOfLevel(Ref ref, String levelId) =>
    ref.watch(intakeRepositoryProvider).fetchCirclesOfLevel(levelId);

/// قائمة الانتظار + إضافة متقدّم + تسجيل اختبار + إسناد لحلقة.
@riverpod
class WaitingListController extends _$WaitingListController {
  @override
  Future<List<WaitingApplicant>> build() {
    return ref.watch(intakeRepositoryProvider).fetchWaiting();
  }

  Future<void> addApplicant({
    required String name,
    required Gender gender,
    required String levelId,
  }) async {
    await ref
        .read(intakeRepositoryProvider)
        .addApplicant(name: name, gender: gender, levelId: levelId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> recordPlacement({
    required String waitingId,
    required String studentPersonId,
    String? supervisorId,
    required String resultLevelId,
    String? notes,
  }) async {
    await ref.read(intakeRepositoryProvider).recordPlacement(
          waitingId: waitingId,
          studentPersonId: studentPersonId,
          supervisorId: supervisorId,
          resultLevelId: resultLevelId,
          notes: notes,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> enroll({
    required String waitingId,
    required String studentPersonId,
    required String circleId,
  }) async {
    await ref.read(intakeRepositoryProvider).enroll(
          waitingId: waitingId,
          studentPersonId: studentPersonId,
          circleId: circleId,
        );
    ref.invalidateSelf();
    await future;
  }
}
