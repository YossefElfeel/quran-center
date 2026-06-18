import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/parent_repository.dart';

part 'child_consents_controller.g.dart';

/// أنواع موافقة الوسائط النشطة للطفل + منح/سحب.
@riverpod
class ChildConsentsController extends _$ChildConsentsController {
  @override
  Future<Set<String>> build(String studentPersonId) =>
      ref.watch(parentRepositoryProvider).fetchActiveConsents(studentPersonId);

  Future<void> setConsent({
    required String scope,
    required bool granted,
  }) async {
    final ParentRepository repo = ref.read(parentRepositoryProvider);
    if (granted) {
      await repo.grantConsent(studentPersonId: studentPersonId, scope: scope);
    } else {
      await repo.revokeConsent(studentPersonId: studentPersonId, scope: scope);
    }
    ref.invalidateSelf();
    await future;
  }
}
