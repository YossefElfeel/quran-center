/// كورس مجاني (فيديو) للعامة + المسجّلين.
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.description,
  });

  factory Course.fromMap(Map<String, dynamic> map) => Course(
    id: map['id'] as String,
    title: map['title'] as String,
    videoUrl: map['video_url'] as String,
    description: map['description'] as String?,
  );

  final String id;
  final String title;
  final String videoUrl;
  final String? description;
}
