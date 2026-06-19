/// عنصر وسائط لطالب (صورة/فيديو) — نموذج عرض. الـ RLS بتفلتر اللي يتشاف
/// (وسائط البنت محجوبة من غير موافقة نشطة).
class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.storagePath,
    required this.watermarked,
    required this.createdAt,
  });

  factory MediaItem.fromMap(Map<String, dynamic> m) => MediaItem(
    id: m['id'] as String,
    type: m['type'] as String,
    storagePath: m['storage_path'] as String,
    watermarked: m['watermarked'] as bool,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  final String id;
  final String type; // 'photo' | 'video'
  final String storagePath;
  final bool watermarked;
  final DateTime createdAt;

  bool get isVideo => type == 'video';
}
