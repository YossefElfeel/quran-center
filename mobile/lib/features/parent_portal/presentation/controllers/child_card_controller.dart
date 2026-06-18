import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/parent_repository.dart';
import '../../domain/child_card.dart';

part 'child_card_controller.g.dart';

/// كارت متابعة طفل معيّن.
@riverpod
Future<ChildCard> childCard(Ref ref, String studentPersonId) =>
    ref.watch(parentRepositoryProvider).fetchChildCard(studentPersonId);
