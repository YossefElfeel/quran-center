import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/subscription_repository.dart';
import '../../domain/household_member_row.dart';

part 'household_members_controller.g.dart';

/// أفراد أسرة + إضافة فرد.
@riverpod
class HouseholdMembersController extends _$HouseholdMembersController {
  @override
  Future<List<HouseholdMemberRow>> build(String householdId) => ref
      .watch(subscriptionRepositoryProvider)
      .fetchHouseholdMembers(householdId);

  Future<void> addMember({
    required String personId,
    required String role,
  }) async {
    await ref
        .read(subscriptionRepositoryProvider)
        .addHouseholdMember(
          householdId: householdId,
          personId: personId,
          role: role,
        );
    ref.invalidateSelf();
    await future;
  }
}
