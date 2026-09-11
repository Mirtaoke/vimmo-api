import '../../data/models/notification_model.dart';

class NotificationState {
  const NotificationState({this.items = const []});
  final List<NotificationModel> items;
  int get unreadCount => items.where((item) => !item.isRead).length;
}
