import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../admin_setup/domain/circle.dart';
import '../../data/session_repository.dart';

part 'my_circles_controller.g.dart';

/// حلقات المعلّم الحالي.
@riverpod
Future<List<Circle>> myCircles(Ref ref) async {
  final String? personId = await ref.watch(currentPersonIdProvider.future);
  if (personId == null) return const <Circle>[];
  return ref.watch(sessionRepositoryProvider).fetchMyCircles(personId);
}
