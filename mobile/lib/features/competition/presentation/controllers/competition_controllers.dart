import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/competition_repository.dart';
import '../../domain/competition_models.dart';

part 'competition_controllers.g.dart';

/// قايمة المسابقات + إنشاء (أدمن).
@riverpod
class Competitions extends _$Competitions {
  @override
  Future<List<CompetitionRow>> build() =>
      ref.watch(competitionRepositoryProvider).fetchCompetitions();

  Future<void> create(String name) async {
    if (name.trim().isEmpty) return;
    await ref
        .read(competitionRepositoryProvider)
        .createCompetition(name.trim());
    ref.invalidateSelf();
    await future;
  }
}

/// متقدّمو مسابقة + تدريج (محكّم/أدمن).
@riverpod
class CompetitionApplications extends _$CompetitionApplications {
  @override
  Future<List<CompetitionApplicationRow>> build(String competitionId) =>
      ref.watch(competitionRepositoryProvider).fetchApplications(competitionId);

  Future<void> score(String applicationId, double score) async {
    await ref
        .read(competitionRepositoryProvider)
        .scoreApplication(applicationId, score);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setStatus(String applicationId, String status) async {
    await ref
        .read(competitionRepositoryProvider)
        .setApplicationStatus(applicationId, status);
    ref.invalidateSelf();
    await future;
  }
}

/// نتائج مسابقة مرتّبة.
@riverpod
Future<List<CompetitionResultRow>> competitionResults(
  Ref ref,
  String competitionId,
) => ref.watch(competitionRepositoryProvider).fetchResults(competitionId);
