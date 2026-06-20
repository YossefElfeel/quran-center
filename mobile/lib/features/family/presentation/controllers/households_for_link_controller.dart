import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/family_repository.dart';
import '../../domain/household_option.dart';

part 'households_for_link_controller.g.dart';

/// الأسر المتاحة لاختيارها عند ربط ولي أمر (أو إنشاء أسرة جديدة).
@riverpod
Future<List<HouseholdOption>> householdsForLink(Ref ref) =>
    ref.watch(familyRepositoryProvider).fetchHouseholds();
