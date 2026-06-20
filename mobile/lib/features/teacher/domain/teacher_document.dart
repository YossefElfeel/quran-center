/// مستند معلّم مرفوع (سيرة ذاتية أو شهادة) — مخزّن في bucket خاص.
class TeacherDocument {
  const TeacherDocument({
    required this.id,
    required this.kind,
    required this.title,
    required this.storagePath,
    required this.createdAt,
    this.mime,
  });

  factory TeacherDocument.fromMap(Map<String, dynamic> map) => TeacherDocument(
    id: map['id'] as String,
    kind: map['kind'] as String,
    title: map['title'] as String,
    storagePath: map['storage_path'] as String,
    mime: map['mime'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  final String id;

  /// 'cv' | 'certificate'.
  final String kind;
  final String title;
  final String storagePath;
  final String? mime;
  final DateTime createdAt;

  bool get isCv => kind == 'cv';
  bool get isPdf =>
      (mime ?? '') == 'application/pdf' ||
      storagePath.toLowerCase().endsWith('.pdf');
}
