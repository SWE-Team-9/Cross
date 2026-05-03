part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

class LoadMoreNotifications extends NotificationsEvent {
  const LoadMoreNotifications();
}

class MarkNotificationRead extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsRead extends NotificationsEvent {
  const MarkAllNotificationsRead();
}

class DeleteNotification extends NotificationsEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class RealtimeNotificationReceived extends NotificationsEvent {
  final NotificationEntity notification;

  const RealtimeNotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class RefreshUnreadCount extends NotificationsEvent {
  const RefreshUnreadCount();
}
