import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/teacher_document.dart';

part 'teacher_docs_repository.g.dart';

/// مستندات المعلّم (سيرة/شهادات): رفع لـ bucket خاص + صف في teacher_document،
/// قراءة بتاعتي (RLS)، حذف (ملف + صف)، ورابط موقّع للعرض.
class TeacherDocsRepository {
  TeacherDocsRepository(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'teacher-docs';

  Future<List<TeacherDocument>> listMine() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('teacher_document')
        .select('id, kind, title, storage_path, mime, created_at')
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 12));
    return rows.map(TeacherDocument.fromMap).toList();
  }

  /// يرفع ملفًا ويسجّله. مفتاح الفولدر = auth.uid() (لسياسة التخزين).
  Future<void> upload({
    required String teacherPersonId,
    required String kind,
    required String title,
    required Uint8List bytes,
    required String ext,
    String? mime,
  }) async {
    final String uid = _client.auth.currentUser!.id;
    final String path = '$uid/${const Uuid().v4()}.$ext';
    await _client.storage
        .from(_bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    await _client.from('teacher_document').insert(<String, dynamic>{
      'teacher_person_id': teacherPersonId,
      'kind': kind,
      'title': title,
      'storage_path': path,
      'mime': ?mime,
    });
  }

  Future<void> delete(TeacherDocument doc) async {
    await _client.storage.from(_bucket).remove(<String>[doc.storagePath]);
    await _client.from('teacher_document').delete().eq('id', doc.id);
  }

  /// رابط موقّع مؤقّت (ساعة) لعرض/تحميل المستند.
  Future<String> signedUrl(String storagePath) => _client.storage
      .from(_bucket)
      .createSignedUrl(storagePath, 3600)
      .timeout(const Duration(seconds: 12));
}

@riverpod
TeacherDocsRepository teacherDocsRepository(Ref ref) =>
    TeacherDocsRepository(ref.watch(supabaseClientProvider));
