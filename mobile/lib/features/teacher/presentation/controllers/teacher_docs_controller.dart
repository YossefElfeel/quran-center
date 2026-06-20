import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../data/teacher_docs_repository.dart';
import '../../domain/teacher_document.dart';

part 'teacher_docs_controller.g.dart';

/// مستنداتي (سيرة + شهادات) — تحميل + رفع + حذف.
@riverpod
class MyTeacherDocuments extends _$MyTeacherDocuments {
  @override
  Future<List<TeacherDocument>> build() =>
      ref.watch(teacherDocsRepositoryProvider).listMine();

  Future<void> upload({
    required String kind,
    required String title,
    required Uint8List bytes,
    required String ext,
    String? mime,
  }) async {
    final String? pid = await ref.read(currentPersonIdProvider.future);
    if (pid == null) return;
    await ref
        .read(teacherDocsRepositoryProvider)
        .upload(
          teacherPersonId: pid,
          kind: kind,
          title: title,
          bytes: bytes,
          ext: ext,
          mime: mime,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(TeacherDocument doc) async {
    await ref.read(teacherDocsRepositoryProvider).delete(doc);
    ref.invalidateSelf();
    await future;
  }
}

/// رابط موقّع لعرض مستند.
@riverpod
Future<String> teacherDocSignedUrl(Ref ref, String storagePath) =>
    ref.watch(teacherDocsRepositoryProvider).signedUrl(storagePath);
