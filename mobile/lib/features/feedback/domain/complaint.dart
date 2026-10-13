/// شكوى (يرفعها أي حد، يردّ عليها المدير).
class Complaint {
  const Complaint({
    required this.id,
    required this.category,
    required this.body,
    required this.status,
    required this.createdAt,
    this.managerResponse,
    this.respondedAt,
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
      respondedAt: map['responded_at'] == null
          ? null
          : DateTime.parse(map['responded_at'] as String),
      authorName: author?['full_name'] as String?,
    );
  }

  final String id;
  final String category;
  final String body;
  final String status;
  final DateTime createdAt;
  final String? managerResponse;
  final DateTime? respondedAt;
  final String? authorName;

  /// رقم مرجعي قصير وثابت يسهل تداوله بدل UUID الكامل.
  String get referenceNumber => complaintReferenceNumber(id);

  /// كود مختصر للقوايم (آخر ٤ حروف من [referenceNumber]) — مثلاً "#A183".
  String get shortReference => complaintShortReference(id);

  bool get isAnswered => managerResponse != null && managerResponse!.isNotEmpty;
}

/// رقم مرجعي من معرّف الشكوى (أول ٨ حروف من الـ UUID بدون شرط).
String complaintReferenceNumber(String id) {
  final String compact = id.replaceAll('-', '').toUpperCase();
  return compact.length <= 8 ? compact : compact.substring(0, 8);
}

/// كود مختصر "#XXXX" (آخر ٤ حروف من [complaintReferenceNumber]).
String complaintShortReference(String id) {
  final String ref = complaintReferenceNumber(id);
  return '#${ref.length <= 4 ? ref : ref.substring(ref.length - 4)}';
}

/// تصنيفات الشكوى (قيم الـ DB) بترتيب العرض في الفورم.
const List<String> complaintCategories = <String>[
  'academic',
  'financial',
  'behavioral',
  'privacy',
  'other',
];
