import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/feedback_repository.dart';
import '../../domain/complaint.dart';

part 'feedback_controllers.g.dart';

/// شكاويّ أنا + رفع شكوى.
@riverpod
class MyComplaints extends _$MyComplaints {
  @override
  Future<List<Complaint>> build() =>
      ref.watch(feedbackRepositoryProvider).fetchMyComplaints();

  Future<void> add({required String category, required String body}) async {
    if (body.trim().isEmpty) return;
    await ref
        .read(feedbackRepositoryProvider)
        .submitComplaint(category: category, body: body.trim());
    ref.invalidateSelf();
    await future;
  }
}

/// صندوق الشكاوى (المدير) + الرد.
@riverpod
class ComplaintInbox extends _$ComplaintInbox {
  @override
  Future<List<Complaint>> build() =>
      ref.watch(feedbackRepositoryProvider).fetchInbox();

  Future<void> respond(String id, String response) async {
    if (response.trim().isEmpty) return;
    await ref.read(feedbackRepositoryProvider).respond(id, response.trim());
    ref.invalidateSelf();
    await future;
  }
}
