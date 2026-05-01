import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
// import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notifications_result.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_unread_count_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository repository;

  setUp(() {
    repository = MockNotificationsRepository();
  });

  test('DeleteNotificationUseCase forwards id', () async {
    const expected = NotificationsResult<void>.success(null);
    when(() => repository.deleteNotification('not_1'))
        .thenAnswer((_) async => expected);

    final result = await DeleteNotificationUseCase(repository)('not_1');

    expect(result, expected);
    verify(() => repository.deleteNotification('not_1')).called(1);
  });

  test('GetUnreadCountUseCase forwards call', () async {
    const expected = NotificationsResult<int>.success(9);
    when(() => repository.getUnreadCount()).thenAnswer((_) async => expected);

    final result = await GetUnreadCountUseCase(repository)();

    expect(result, expected);
    verify(() => repository.getUnreadCount()).called(1);
  });

  test('MarkNotificationAsReadUseCase forwards id', () async {
    const expected = NotificationsResult<void>.success(null);
    when(() => repository.markAsRead('not_2'))
        .thenAnswer((_) async => expected);

    final result = await MarkNotificationAsReadUseCase(repository)('not_2');

    expect(result, expected);
    verify(() => repository.markAsRead('not_2')).called(1);
  });

  test('MarkAllNotificationsAsReadUseCase forwards call', () async {
    const expected = NotificationsResult<void>.success(null);
    when(() => repository.markAllAsRead()).thenAnswer((_) async => expected);

    final result = await MarkAllNotificationsAsReadUseCase(repository)();

    expect(result, expected);
    verify(() => repository.markAllAsRead()).called(1);
  });
}
