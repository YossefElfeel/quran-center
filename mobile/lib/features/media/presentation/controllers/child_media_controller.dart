import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/media_repository.dart';
import '../../domain/media_item.dart';

part 'child_media_controller.g.dart';

/// وسائط الطالب (الـ RLS بتفلتر اللي يتشاف حسب الموافقة/الدور).
@riverpod
Future<List<MediaItem>> childMedia(Ref ref, String studentPersonId) =>
    ref.watch(mediaRepositoryProvider).listMedia(studentPersonId);

/// رابط موقّع مؤقّت لوسيط (يُطلب عند العرض؛ بيسجّل الوصول).
@riverpod
Future<String> mediaSignedUrl(Ref ref, String mediaId) =>
    ref.watch(mediaRepositoryProvider).signedUrl(mediaId);
