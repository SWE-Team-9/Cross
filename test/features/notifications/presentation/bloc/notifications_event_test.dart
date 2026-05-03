import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';

void main() {
  test('MarkNotificationRead props include id', () {
    expect(const MarkNotificationRead('not_1').props, ['not_1']);
  });

  test('DeleteNotification props include id', () {
    expect(const DeleteNotification('not_2').props, ['not_2']);
  });

  test('RealtimeNotificationReceived props include notification', () {
    final notification = NotificationEntity(
      id: 'not_3',
      type: NotificationType.like,
      message: 'Ali liked your track Song2',
      actorId: 'usr_1',
      entityType: 'track',
      entityId: 'trk_1',
      isRead: false,
      createdAt: DateTime(2026, 3, 7),
    );

    expect(RealtimeNotificationReceived(notification).props, [notification]);
  });

  test('stateless events have empty props', () {
    expect(const LoadNotifications().props, isEmpty);
    expect(const LoadMoreNotifications().props, isEmpty);
    expect(const MarkAllNotificationsRead().props, isEmpty);
    expect(const RefreshUnreadCount().props, isEmpty);
  });
}
