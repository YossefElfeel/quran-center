/// تعليق من ولي أمر على ملف ابنه (تواصل من البيت للمركز).
class ParentComment {
  const ParentComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory ParentComment.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? author = map['author'] as Map<String, dynamic>?;
    return ParentComment(
      id: map['id'] as String,
      authorName: (author?['full_name'] as String?) ?? 'ولي الأمر',
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;
}
