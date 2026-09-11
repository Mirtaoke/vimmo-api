class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });
  final String id, title, message, type;
  final DateTime createdAt;
  final bool isRead;
}
