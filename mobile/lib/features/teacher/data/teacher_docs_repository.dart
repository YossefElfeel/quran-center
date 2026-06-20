import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/app_exception.dart';
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

  /// أقصى حجم لملف المستند (٢٠ ميجا).
  static const int maxUploadBytes = 20 * 1024 * 1024;

  /// يرفع ملفًا ويسجّله. مفتاح الفولدر = auth.uid() (لسياسة التخزين).
  /// بيتأكّد من الحجم/الجلسة، ولو فشل تسجيل الصف بعد الرفع بينظّف الملف اليتيم.
  Future<void> upload({
    required String teacherPersonId,
    required String kind,
    required String title,
    required Uint8List bytes,
    required String ext,
    String? mime,
  }) async {
    if (bytes.length > maxUploadBytes) {
      throw const ValidationException('الملف أكبر من ٢٠ ميجا — اختار ملف أصغر');
    }
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const ValidationException('انتهت الجلسة — سجّل دخول تاني');
    }
    final String path = '${user.id}/${const Uuid().v4()}.$ext';
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime),
          );
    } catch (_) {
      throw const ValidationException('مش قادرين نرفع الملف — جرّب تاني');
    }
    try {
      await _client.from('teacher_document').insert(<String, dynamic>{
        'teacher_person_id': teacherPersonId,
        'kind': kind,
        'title': title,
        'storage_path': path,
        'mime': ?mime,
      });
    } catch (_) {
      // فشل تسجيل الصف بعد الرفع → نظّف الملف اليتيم عشان ما يفضلش في التخزين.
      try {
        await _client.storage.from(_bucket).remove(<String>[path]);
      } catch (_) {}
      throw const ValidationException('مش قادرين نسجّل المستند — جرّب تاني');
    }
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
