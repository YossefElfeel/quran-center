/// شكوى (يرفعها أي حد، يردّ عليها المدير).
class Complaint {
  const Complaint({
    required this.id,
    required this.category,
    required this.body,
    required this.status,
    required this.createdAt,
    this.managerResponse,
    this.authorName,
  });

  factory Complaint.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? author = map['author'] as Map<String, dynamic>?;
    return Complaint(
      id: map['id'] as String,
      category: map['category'] as String,
      body: map['body'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      managerResponse: map['manager_response'] as String?,
      authorName: author?['full_name'] as String?,
    );
  }

  final String id;
  final String category;
  final String body;
  final String status;
  final DateTime createdAt;
  final String? managerResponse;
  final String? authorName;

  bool get isAnswered => managerResponse != null && managerResponse!.isNotEmpty;

  String get statusAr => switch (status) {
    'open' => 'مفتوحة',
    'answered' => 'تم الرد',
    'reopened' => 'أعيد فتحها',
    'closed' => 'مقفولة',
    _ => status,
  };
}

/// تصنيفات الشكوى (للعرض في الفورم).
const Map<String, String> complaintCategoriesAr = <String, String>{
  'academic': 'أكاديمي',
  'financial': 'مالي',
  'behavioral': 'سلوكي',
  'privacy': 'خصوصية',
  'other': 'أخرى',
};
