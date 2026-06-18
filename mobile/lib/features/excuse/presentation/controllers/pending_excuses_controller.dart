import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../data/excuse_repository.dart';
import '../../domain/pending_excuse.dart';

part 'pending_excuses_controller.g.dart';

/// طابور أعذار الغياب المعلّقة + قرار الموافقة/الرفض.
@riverpod
class PendingExcusesController extends _$PendingExcusesController {
  @override
  Future<List<PendingExcuse>> build() =>
      ref.watch(excuseRepositoryProvider).fetchPending();

  Future<void> decide(PendingExcuse excuse, {required bool approve}) async {
    final String? supervisorId = await ref.read(currentPersonIdProvider.future);
    await ref
        .read(excuseRepositoryProvider)
        .decide(
          excuseId: excuse.id,
          approve: approve,
          enrollmentId: excuse.enrollmentId,
          sessionId: excuse.sessionId,
          supervisorId: supervisorId,
        );
    ref.invalidateSelf();
    await future;
  }
}
