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
    this.readAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String,
    type: map['type'] as String,
    title: map['title'] as String,
    body: map['body'] as String?,
    circleId:
        (map['route_data'] as Map<String, dynamic>?)?['circle_id'] as String?,
    month: (map['route_data'] as Map<String, dynamic>?)?['month'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    readAt: map['read_at'] != null
        ? DateTime.parse(map['read_at'] as String)
        : null,
  );

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? circleId;
  final String? month;
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
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
  );
}
