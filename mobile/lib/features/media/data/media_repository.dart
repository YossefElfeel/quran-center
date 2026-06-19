import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/media_item.dart';

part 'media_repository.g.dart';

/// وسائط الطالب: الرفع عبر Edge (`upload-media`، بيخزّن في bucket خاص ويطبّق
/// الموافقة عبر RLS)، القراءة من جدول `media` (الـ RLS بتفلتر المسموح)، والروابط
/// الموقّعة عبر Edge (`media-signed-url`، بتسجّل الوصول). البايتس بتتعالج على
/// الجهاز (علامة مائية/ضغط) قبل ما توصل هنا.
class MediaRepository {
  MediaRepository(this._client);

  final SupabaseClient _client;

  /// يرفع وسيطًا مُعالَجًا. الموافقة/الصلاحية بتتطبّق سيرفر-سايد عبر RLS.
  Future<void> uploadMedia({
    required String studentPersonId,
    required String type, // 'photo' | 'video'
    required Uint8List bytes,
    required bool watermarked,
  }) async {
    try {
      await _client.functions.invoke(
        'upload-media',
        body: bytes,
        queryParameters: <String, dynamic>{
          'student_person_id': studentPersonId,
          'type': type,
          'watermarked': watermarked.toString(),
        },
      );
    } on FunctionException catch (e) {
      if (e.status == 403) {
        throw const PermissionDeniedException(
          'محتاج موافقة ولي الأمر للوسائط دي',
        );
      }
      throw const ValidationException('مش قادرين نرفع الوسيط — جرّب تاني');
    }
  }

  /// وسائط الطالب (الأحدث أولًا). الـ RLS بتحجب وسائط البنت من غير موافقة.
  Future<List<MediaItem>> listMedia(String studentPersonId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('media')
        .select('id, type, storage_path, watermarked, created_at')
        .eq('student_person_id', studentPersonId)
        .order('created_at', ascending: false);
    return rows.map(MediaItem.fromMap).toList();
  }

  /// رابط موقّع مؤقّت لعرض الوسيط (بيسجّل الوصول في audit_log).
  Future<String> signedUrl(String mediaId) async {
    try {
      final FunctionResponse res = await _client.functions.invoke(
        'media-signed-url',
        body: <String, dynamic>{'media_id': mediaId},
      );
      final dynamic data = res.data;
      if (data is Map && data['url'] is String) {
        return data['url'] as String;
      }
      throw const ValidationException('مش قادرين نجيب رابط الوسيط');
    } on FunctionException catch (_) {
      throw const ValidationException('مش قادرين نجيب رابط الوسيط');
    }
  }
}

@riverpod
MediaRepository mediaRepository(Ref ref) =>
    MediaRepository(ref.watch(supabaseClientProvider));
