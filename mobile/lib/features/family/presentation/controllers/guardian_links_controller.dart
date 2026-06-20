import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/family_repository.dart';
import '../../domain/guardian_link_row.dart';

part 'guardian_links_controller.g.dart';

/// روابط أولياء الأمور بالأطفال + إنشاء ربط جديد.
@riverpod
class GuardianLinksController extends _$GuardianLinksController {
  @override
  Future<List<GuardianLinkRow>> build() =>
      ref.watch(familyRepositoryProvider).fetchLinks();

  Future<void> createLink({
    required String guardianName,
    required String childPersonId,
    required String relation,
    String? householdId,
    String? newHouseholdName,
  }) async {
    await ref
        .read(familyRepositoryProvider)
        .createGuardianWithHousehold(
          guardianName: guardianName,
          childPersonId: childPersonId,
          relation: relation,
          householdId: householdId,
          newHouseholdName: newHouseholdName,
        );
    ref.invalidateSelf();
    await future;
  }
}
