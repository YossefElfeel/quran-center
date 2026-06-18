import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/subscription_repository.dart';
import '../../domain/person_option.dart';

part 'all_persons_controller.g.dart';

/// كل الأشخاص (لاختيار فرد يتضاف للأسرة).
@riverpod
Future<List<PersonOption>> allPersons(Ref ref) =>
    ref.watch(subscriptionRepositoryProvider).fetchAllPersons();
