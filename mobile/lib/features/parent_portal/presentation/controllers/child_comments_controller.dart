import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/parent_repository.dart';
import '../../domain/parent_comment.dart';

part 'child_comments_controller.g.dart';

/// تعليقات ولي الأمر على طفل + إضافة تعليق.
@riverpod
class ChildCommentsController extends _$ChildCommentsController {
  @override
  Future<List<ParentComment>> build(String studentPersonId) =>
      ref.watch(parentRepositoryProvider).fetchComments(studentPersonId);

  Future<void> add(String body) async {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await ref
        .read(parentRepositoryProvider)
        .addComment(studentPersonId: studentPersonId, body: trimmed);
    ref.invalidateSelf();
    await future;
  }
}
