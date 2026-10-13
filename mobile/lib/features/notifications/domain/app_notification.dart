/// إشعار داخل التطبيق.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.circleId,
    this.month,
    this.complaintId,
    this.readAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? routeData =
        map['route_data'] as Map<String, dynamic>?;
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String?,
      circleId: routeData?['circle_id'] as String?,
      month: routeData?['month'] as String?,
      complaintId: routeData?['complaint_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
    );
  }

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? circleId;
  final String? month;

  /// معرّف الشكوى (route_data.complaint_id) لإشعارات تصعيد الشكاوى — لو موجود.
  final String? complaintId;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    circleId: circleId,
    month: month,
    complaintId: complaintId,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
  );
}
