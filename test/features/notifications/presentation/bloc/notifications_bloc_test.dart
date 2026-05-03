import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notifications_result.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_unread_count_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';

class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockMarkNotificationAsReadUseCase extends Mock
    implements MarkNotificationAsReadUseCase {}

class MockMarkAllNotificationsAsReadUseCase extends Mock
    implements MarkAllNotificationsAsReadUseCase {}

class MockDeleteNotificationUseCase extends Mock
    implements DeleteNotificationUseCase {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

NotificationEntity makeNotification({
  String id = 'not_1',
  bool isRead = false,
  NotificationType type = NotificationType.like,
}) {
  return NotificationEntity(
    id: id,
    type: type,
    message: 'Ali liked your track Song2',
    actorId: 'usr_1',
    actorDisplayName: 'Ali',
    actorHandle: 'ali',
    entityType: 'track',
    entityId: 'trk_1',
    trackName: 'Song2',
    isRead: isRead,
    createdAt: DateTime(2026, 3, 7),
  );
}

void main() {
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockGetUnreadCountUseCase mockGetUnreadCount;
  late MockMarkNotificationAsReadUseCase mockMarkAsRead;
  late MockMarkAllNotificationsAsReadUseCase mockMarkAllAsRead;
  late MockDeleteNotificationUseCase mockDelete;
  late MockNotificationsRepository mockRepository;

  NotificationsBloc createBloc() {
    return NotificationsBloc(
      getNotifications: mockGetNotifications,
      getUnreadCount: mockGetUnreadCount,
      markAsRead: mockMarkAsRead,
      markAllAsRead: mockMarkAllAsRead,
      delete: mockDelete,
      repository: mockRepository,
    );
  }

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockGetUnreadCount = MockGetUnreadCountUseCase();
    mockMarkAsRead = MockMarkNotificationAsReadUseCase();
    mockMarkAllAsRead = MockMarkAllNotificationsAsReadUseCase();
    mockDelete = MockDeleteNotificationUseCase();
    mockRepository = MockNotificationsRepository();

    when(() => mockRepository.notificationStream)
        .thenAnswer((_) => const Stream<NotificationEntity>.empty());
  });

  group('LoadNotifications', () {
    test('initial state is NotificationsInitial', () {
      final bloc = createBloc();
      expect(bloc.state, const NotificationsInitial());
      bloc.close();
    });

    blocTest<NotificationsBloc, NotificationsState>(
      'emits loading then loaded on success',
      build: () {
        when(() => mockGetNotifications(page: 1, limit: 20)).thenAnswer(
          (_) async => NotificationsResult.success([makeNotification()]),
        );
        when(() => mockGetUnreadCount())
            .thenAnswer((_) async => const NotificationsResult.success(1));
        return createBloc();
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [
        const NotificationsLoading(),
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.length, 'length', 1)
            .having((s) => s.unreadCount, 'unreadCount', 1)
            .having((s) => s.currentPage, 'currentPage', 1),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits error when notifications call fails',
      build: () {
        when(() => mockGetNotifications(page: 1, limit: 20)).thenAnswer(
          (_) async => NotificationsResult.failure(
            const ServerFailure('Server error'),
          ),
        );
        when(() => mockGetUnreadCount())
            .thenAnswer((_) async => const NotificationsResult.success(0));
        return createBloc();
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [
        const NotificationsLoading(),
        const NotificationsError(
          'Unable to load notifications right now. Please try again.',
        ),
      ],
    );
  });

  group('LoadMoreNotifications', () {
    final existing = [makeNotification(id: 'not_1')];
    final nextPage = [makeNotification(id: 'not_2')];

    blocTest<NotificationsBloc, NotificationsState>(
      'appends page and updates current page',
      build: () {
        when(() => mockGetNotifications(page: 2, limit: 20)).thenAnswer(
          (_) async => NotificationsResult.success(nextPage),
        );
        return createBloc();
      },
      seed: () => NotificationsLoaded(
        notifications: existing,
        unreadCount: 1,
        hasMore: true,
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(const LoadMoreNotifications()),
      expect: () => [
        isA<NotificationsLoadingMore>(),
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.length, 'merged count', 2)
            .having((s) => s.currentPage, 'currentPage', 2),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits error when load more fails',
      build: () {
        when(() => mockGetNotifications(page: 2, limit: 20)).thenAnswer(
          (_) async => NotificationsResult.failure(
            const ServerFailure('Server error'),
          ),
        );
        return createBloc();
      },
      seed: () => NotificationsLoaded(
        notifications: existing,
        unreadCount: 1,
        hasMore: true,
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(const LoadMoreNotifications()),
      expect: () => [
        isA<NotificationsLoadingMore>(),
        const NotificationsError(
          'Unable to load notifications right now. Please try again.',
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'does nothing if hasMore is false',
      build: () => createBloc(),
      seed: () => NotificationsLoaded(
        notifications: existing,
        unreadCount: 0,
        hasMore: false,
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(const LoadMoreNotifications()),
      expect: () => <NotificationsState>[],
    );
  });

  group('MarkNotificationRead', () {
    final unread = makeNotification(id: 'not_1', isRead: false);
    final read = makeNotification(id: 'not_2', isRead: true);

    blocTest<NotificationsBloc, NotificationsState>(
      'optimistically marks unread notification as read and decrements unread',
      build: () {
        when(() => mockMarkAsRead('not_1')).thenAnswer(
          (_) async => const NotificationsResult.success(null),
        );
        return createBloc();
      },
      seed: () => NotificationsLoaded(
        notifications: [unread],
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const MarkNotificationRead('not_1')),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.first.isRead, 'isRead', true)
            .having((s) => s.unreadCount, 'unreadCount', 0),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'keeps unread count when notification was already read',
      build: () {
        when(() => mockMarkAsRead('not_2')).thenAnswer(
          (_) async => const NotificationsResult.success(null),
        );
        return createBloc();
      },
      seed: () => NotificationsLoaded(
        notifications: [read],
        unreadCount: 0,
      ),
      act: (bloc) => bloc.add(const MarkNotificationRead('not_2')),
      expect: () => <NotificationsState>[],
    );
  });

  group('MarkAllNotificationsRead', () {
    final notifs = [
      makeNotification(id: 'not_1', isRead: false),
      makeNotification(id: 'not_2', isRead: false),
    ];

    blocTest<NotificationsBloc, NotificationsState>(
      'marks all read and sets unreadCount to zero',
      build: () {
        when(() => mockMarkAllAsRead()).thenAnswer(
          (_) async => const NotificationsResult.success(null),
        );
        return createBloc();
      },
      seed: () => NotificationsLoaded(
        notifications: notifs,
        unreadCount: 2,
      ),
      act: (bloc) => bloc.add(const MarkAllNotificationsRead()),
      expect: () => [
        isA<NotificationsLoaded>()
            .having(
                (s) => s.notifications.every((n) => n.isRead), 'allRead', true)
            .having((s) => s.unreadCount, 'unreadCount', 0),
      ],
    );
  });

  group('DeleteNotification', () {
    final notif = makeNotification(id: 'not_1');

    blocTest<NotificationsBloc, NotificationsState>(
      'removes notification from list',
      build: () {
        when(() => mockDelete('not_1')).thenAnswer(
          (_) async => const NotificationsResult.success(null),
        );
        return createBloc();
      },
      seed: () => NotificationsLoaded(
        notifications: [notif],
        unreadCount: 0,
      ),
      act: (bloc) => bloc.add(const DeleteNotification('not_1')),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.notifications, 'notifications', isEmpty),
      ],
    );
  });

  group('RealtimeNotificationReceived', () {
    final existing = makeNotification(id: 'not_1');
    final realtime = makeNotification(id: 'not_realtime', isRead: false);

    blocTest<NotificationsBloc, NotificationsState>(
      'prepends realtime notification and increments unread count',
      build: () => createBloc(),
      seed: () => NotificationsLoaded(
        notifications: [existing],
        unreadCount: 0,
      ),
      act: (bloc) => bloc.add(RealtimeNotificationReceived(realtime)),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.first.id, 'first id', 'not_realtime')
            .having((s) => s.unreadCount, 'unreadCount', 1),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'ignores duplicate realtime notifications',
      build: () => createBloc(),
      seed: () => NotificationsLoaded(
        notifications: [existing],
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(RealtimeNotificationReceived(existing)),
      expect: () => <NotificationsState>[],
    );
  });

  group('RefreshUnreadCount', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'updates unread count when the repository returns a value',
      build: () {
        when(() => mockGetUnreadCount())
            .thenAnswer((_) async => const NotificationsResult.success(7));
        return createBloc();
      },
      seed: () => NotificationsLoaded(
        notifications: [makeNotification()],
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const RefreshUnreadCount()),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.unreadCount, 'unreadCount', 7),
      ],
    );
  });
}
