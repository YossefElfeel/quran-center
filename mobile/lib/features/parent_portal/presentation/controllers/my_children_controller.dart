import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/parent_repository.dart';
import '../../domain/child_summary.dart';

part 'my_children_controller.g.dart';

/// أولاد ولي الأمر الحالي.
@riverpod
Future<List<ChildSummary>> myChildren(Ref ref) =>
    ref.watch(parentRepositoryProvider).fetchMyChildren();
